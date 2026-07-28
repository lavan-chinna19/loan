import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../localization.dart';
import '../api_service.dart';

class CreateLoanScreen extends StatefulWidget {
  final String borrowerId;
  final LanguageNotifier languageNotifier;
  
  const CreateLoanScreen({super.key, required this.borrowerId, required this.languageNotifier});

  @override
  State<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends State<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController(text: "3.00");
  final _tenureController = TextEditingController(text: "12");

  String _interestModel = "MODEL_A"; // MODEL_A, MODEL_B
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? _previewData;
  bool _isSaving = false;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _onModelChanged(String? val) {
    if (val != null) {
      setState(() {
        _interestModel = val;
        _previewData = null; // Clear old preview
        
        if (val == "MODEL_B") {
          _rateController.text = "0.00";
          _tenureController.text = "12";
        } else {
          _rateController.text = "3.00";
          _tenureController.text = "12";
        }
      });
    }
  }

  Future<void> _handlePreview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewData = null;
    });

    final data = {
      'borrower_id': widget.borrowerId,
      'principal_amount': double.parse(_principalController.text.trim()),
      'interest_model': _interestModel,
      'interest_rate': double.parse(_rateController.text.trim()),
      'tenure_value': int.parse(_tenureController.text.trim()),
      'tenure_unit': _interestModel == "MODEL_A" ? "MONTHS" : "WEEKS",
    };

    try {
      final res = await ApiService.previewLoan(data);
      setState(() {
        _previewData = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleCreate() async {
    if (_previewData == null) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = {
      'borrower_id': widget.borrowerId,
      'principal_amount': double.parse(_principalController.text.trim()),
      'interest_model': _interestModel,
      'interest_rate': double.parse(_rateController.text.trim()),
      'tenure_value': int.parse(_tenureController.text.trim()),
      'tenure_unit': _interestModel == "MODEL_A" ? "MONTHS" : "WEEKS",
    };

    try {
      await ApiService.createLoan(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageNotifier.isTelugu 
                  ? 'రుణం విజయవంతంగా సృష్టించబడింది. ఆమోదం కోసం వేచి ఉంది!' 
                  : 'Loan created successfully! Pending approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text(ln.translate('create_loan')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _interestModel,
                decoration: InputDecoration(
                  labelText: ln.translate('interest_model'),
                  prefixIcon: const Icon(Icons.calculate_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: "MODEL_A",
                    child: Text(ln.translate('model_a_label')),
                  ),
                  DropdownMenuItem(
                    value: "MODEL_B",
                    child: Text(ln.translate('model_b_label')),
                  ),
                ],
                onChanged: _onModelChanged,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _principalController,
                decoration: InputDecoration(
                  labelText: ln.translate('principal_amount'),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return ln.isTelugu ? 'మొత్తం నమోదు చేయండి' : 'Enter amount';
                  }
                  if (double.tryParse(val) == null || double.parse(val) <= 0) {
                    return ln.isTelugu ? 'సరైన సంఖ్యను ఇవ్వండి' : 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _rateController,
                decoration: InputDecoration(
                  labelText: ln.translate('interest_rate_monthly'),
                  prefixIcon: const Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: _interestModel == "MODEL_A",
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return ln.isTelugu ? 'వడ్డీ రేటు ఇవ్వండి' : 'Enter rate';
                  }
                  if (double.tryParse(val) == null) {
                    return ln.isTelugu ? 'తప్పుడు వడ్డీ రేటు' : 'Enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _tenureController,
                decoration: InputDecoration(
                  labelText: ln.translate('tenure') + (_interestModel == "MODEL_A" ? " (${ln.isTelugu ? 'నెలలు' : 'Months'})" : " (${ln.isTelugu ? 'వారాలు' : 'Weeks'})"),
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                enabled: _interestModel == "MODEL_A",
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return ln.isTelugu ? 'వ్యవధి నమోదు చేయండి' : 'Enter tenure';
                  }
                  if (int.tryParse(val) == null || int.parse(val) <= 0) {
                    return ln.isTelugu ? 'వ్యవధి తప్పు' : 'Enter a valid tenure';
                  }
                  return null;
                },
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
                onPressed: _isLoading ? null : _handlePreview,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Text(ln.translate('preview_schedule')),
              ),
              const SizedBox(height: 24),
              
              if (_previewData != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  ln.isTelugu ? 'షెడ్యూల్ ప్రివ్యూ సారాంశం' : 'Schedule Preview Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ln.translate('total_repayable'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormatter.format(double.parse(_previewData!['total_repayable_amount'].toString())),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (_previewData!['schedules'] as List).length,
                  itemBuilder: (context, index) {
                    final item = _previewData!['schedules'][index];
                    final double dueAmt = double.parse(item['total_due'].toString());
                    
                    return Card(
                      color: Colors.white.withOpacity(0.02),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        title: Text('${ln.isTelugu ? 'వాయిదా' : 'Installment'} #${item['installment_no']}'),
                        subtitle: Text(item['due_date']),
                        trailing: Text(
                          currencyFormatter.format(dueAmt),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text(ln.translate('save_loan')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
