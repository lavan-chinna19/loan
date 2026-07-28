import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization.dart';
import '../api_service.dart';

class CollectPaymentScreen extends StatefulWidget {
  final String loanId;
  final String borrowerName;
  final LanguageNotifier languageNotifier;
  
  const CollectPaymentScreen({
    super.key, 
    required this.loanId, 
    required this.borrowerName,
    required this.languageNotifier
  });

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _remarksController = TextEditingController();

  String _paymentMethod = "CASH"; // CASH, UPI
  String? _selectedScheduleId; // Optional specific schedule installment
  
  List<dynamic> _schedules = [];
  bool _isLoadingSchedules = true;
  bool _isSaving = false;
  String? _errorMessage;

  // After payment completes:
  Map<String, dynamic>? _savedPaymentResult;
  String? _whatsappReceiptText;
  String? _whatsappShareUrl;
  bool _isLoadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchedules() async {
    try {
      final loanDetails = await ApiService.getLoanDetails(widget.loanId);
      final list = loanDetails['schedules'] as List;
      final pendingSchedules = list.where((item) => item['status'] != 'PAID').toList();
      
      setState(() {
        _schedules = pendingSchedules;
        _isLoadingSchedules = false;
        
        if (pendingSchedules.isNotEmpty) {
          final firstPending = pendingSchedules[0];
          final double due = double.parse(firstPending['total_due'].toString());
          final double paid = double.parse(firstPending['amount_paid'].toString());
          _amountController.text = (due - paid).toStringAsFixed(2);
          _selectedScheduleId = firstPending['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingSchedules = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = {
      'loan_id': widget.loanId,
      'payment_schedule_id': _selectedScheduleId, // Optional, can be null for auto-distribution
      'amount_paid': double.parse(_amountController.text.trim()),
      'payment_method': _paymentMethod,
      'reference_no': _paymentMethod == "UPI" && _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
      'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    };

    try {
      final paymentRes = await ApiService.collectPayment(data);
      setState(() {
        _savedPaymentResult = paymentRes;
        _isSaving = false;
      });
      
      _fetchWhatsAppReceipt(paymentRes['id']);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _fetchWhatsAppReceipt(String paymentId) async {
    setState(() {
      _isLoadingReceipt = true;
    });
    try {
      final receiptData = await ApiService.getWhatsAppReceipt(paymentId);
      setState(() {
        _whatsappReceiptText = receiptData['receipt_text'];
        _whatsappShareUrl = receiptData['share_url'];
        _isLoadingReceipt = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReceipt = false;
      });
    }
  }

  Future<void> _shareOnWhatsApp() async {
    if (_whatsappShareUrl == null) return;
    final url = Uri.parse(_whatsappShareUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp. Receipt copied to clip...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;

    if (_savedPaymentResult != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(ln.translate('payment_saved')),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                ln.translate('payment_saved'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green),
              ),
              const SizedBox(height: 24),
              
              if (_isLoadingReceipt)
                const Center(child: CircularProgressIndicator())
              else if (_whatsappReceiptText != null) ...[
                Card(
                  color: Colors.white.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _whatsappReceiptText!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: _shareOnWhatsApp,
                  icon: const Icon(Icons.share),
                  label: Text(ln.translate('share_whatsapp')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(ln.isTelugu ? 'ముగించు' : 'Back to Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${ln.translate('collect_payment')}: ${widget.borrowerName}'),
      ),
      body: _isLoadingSchedules
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String?>(
                      value: _selectedScheduleId,
                      decoration: InputDecoration(
                        labelText: ln.isTelugu ? 'చెల్లించే వాయిదా' : 'Installment to Pay',
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(ln.isTelugu ? 'ఆటోమేటిక్ (పాత బకాయిలు ముందుగా)' : 'Auto-Distribute (Oldest First)'),
                        ),
                        ..._schedules.map((item) {
                          final double due = double.parse(item['total_due'].toString());
                          final double paid = double.parse(item['amount_paid'].toString());
                          final remaining = due - paid;
                          return DropdownMenuItem<String?>(
                            value: item['id'],
                            child: Text('${ln.isTelugu ? 'వాయిదా' : 'Installment'} #${item['installment_no']} (₹${remaining.toStringAsFixed(2)} due)'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedScheduleId = val;
                          if (val != null) {
                            final selectedSched = _schedules.firstWhere((item) => item['id'] == val);
                            final double due = double.parse(selectedSched['total_due'].toString());
                            final double paid = double.parse(selectedSched['amount_paid'].toString());
                            _amountController.text = (due - paid).toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: ln.translate('amount_to_pay'),
                        prefixIcon: const Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return ln.isTelugu ? 'మొత్తం నమోదు చేయండి' : 'Enter amount';
                        }
                        if (double.tryParse(val) == null || double.parse(val) <= 0) {
                          return ln.isTelugu ? 'సరైన మొత్తం ఇవ్వండి' : 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: ln.translate('payment_method'),
                        prefixIcon: const Icon(Icons.payment_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "CASH",
                          child: Text(ln.translate('cash')),
                        ),
                        DropdownMenuItem(
                          value: "UPI",
                          child: Text(ln.translate('upi')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _paymentMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    if (_paymentMethod == "UPI") ...[
                      TextFormField(
                        controller: _refController,
                        decoration: InputDecoration(
                          labelText: ln.translate('reference_no'),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    TextFormField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        labelText: ln.translate('remarks'),
                        prefixIcon: const Icon(Icons.comment_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(ln.translate('save_payment')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
