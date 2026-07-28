import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../localization.dart';
import '../api_service.dart';
import 'create_loan_screen.dart';
import 'collect_payment_screen.dart';

class BorrowerDetailScreen extends StatefulWidget {
  final String borrowerId;
  final LanguageNotifier languageNotifier;
  
  const BorrowerDetailScreen({super.key, required this.borrowerId, required this.languageNotifier});

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  Map<String, dynamic>? _borrower;
  List<dynamic> _loans = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Track currently expanded loan ID to show its schedule
  String? _expandedLoanId;
  Map<String, dynamic>? _selectedLoanDetails;
  bool _isLoadingSchedule = false;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final borrowerData = await ApiService.getBorrowerDetail(widget.borrowerId);
      final loansData = await ApiService.getBorrowerLoans(widget.borrowerId);
      
      setState(() {
        _borrower = borrowerData;
        _loans = loansData;
        _isLoading = false;
      });
      
      if (_expandedLoanId != null) {
        _fetchLoanSchedule(_expandedLoanId!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.languageNotifier.isTelugu 
            ? 'వివరాలు లోడ్ చేయడం విఫలమైంది' 
            : 'Failed to load details';
      });
    }
  }

  Future<void> _fetchLoanSchedule(String loanId) async {
    setState(() {
      _isLoadingSchedule = true;
    });
    try {
      final details = await ApiService.getLoanDetails(loanId);
      setState(() {
        _selectedLoanDetails = details;
        _isLoadingSchedule = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchedule = false;
      });
    }
  }

  Future<void> _approveLoan(String loanId) async {
    final ln = widget.languageNotifier;
    try {
      await ApiService.approveLoan(loanId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ln.isTelugu 
                ? 'రుణం విజయవంతంగా ఆమోదించబడింది మరియు పంపిణీ చేయబడింది!' 
                : 'Loan approved and disbursed successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _fetchDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FULLY_PAID':
        return Colors.blue;
      case 'DEFAULTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTranslatedStatus(String status, LanguageNotifier ln) {
    switch (status) {
      case 'PENDING':
        return ln.translate('loan_status_pending');
      case 'ACTIVE':
        return ln.translate('loan_status_active');
      case 'FULLY_PAID':
        return ln.translate('loan_status_fully_paid');
      case 'DEFAULTED':
        return ln.translate('loan_status_defaulted');
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;
    final isAdmin = ApiService.userRole == 'ADMIN';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _borrower == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_errorMessage ?? 'Error', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_borrower!['first_name_en']} ${_borrower!['last_name_en']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borrower profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ln.isTelugu ? 'వ్యక్తిగత ప్రొఫైల్' : 'Borrower Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(ln.translate('phone_number')),
                      subtitle: Text(_borrower!['phone_number']),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_borrower!['alternative_phone'] != null)
                      ListTile(
                        leading: const Icon(Icons.phone_iphone),
                        title: Text(ln.translate('alternative_phone')),
                        subtitle: Text(_borrower!['alternative_phone']),
                        contentPadding: EdgeInsets.zero,
                      ),
                    if (_borrower!['address_en'] != null)
                      ListTile(
                        leading: const Icon(Icons.home_outlined),
                        title: Text(ln.translate('address')),
                        subtitle: Text(_borrower!['address_en']),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Loans section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ln.translate('loans'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateLoanScreen(
                          borrowerId: widget.borrowerId,
                          languageNotifier: ln,
                        ),
                      ),
                    ).then((_) => _fetchDetails());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(ln.translate('create_loan')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Loans list view
            _loans.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text(ln.isTelugu ? 'ఎలాంటి రుణాలు లేవు' : 'No active loans')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      final loanId = loan['id'];
                      final isExpanded = _expandedLoanId == loanId;
                      final status = loan['status'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                currencyFormatter.format(double.parse(loan['principal_amount'].toString())),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text(
                                loan['interest_model'] == 'MODEL_A' 
                                    ? ln.translate('model_a_label') 
                                    : ln.translate('model_b_label'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.2),
                                      border: Border.all(color: _getStatusColor(status)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getTranslatedStatus(status, ln),
                                      style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedLoanId = null;
                                    _selectedLoanDetails = null;
                                  } else {
                                    _expandedLoanId = loanId;
                                    _fetchLoanSchedule(loanId);
                                  }
                                });
                              },
                            ),
                            
                            // Collapsible schedules breakdown
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              if (_isLoadingSchedule)
                                const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_selectedLoanDetails != null) ...[
                                _buildLoanSummaryMetrics(ln),
                                const Divider(height: 1),
                                
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(ln.translate('installment_no'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text(ln.translate('due_date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text(ln.isTelugu ? 'బ్యాలెన్స్ (₹)' : 'Due (₹)', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                      Expanded(flex: 3, child: Text(ln.translate('status'), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_selectedLoanDetails!['schedules'] as List).length,
                                  itemBuilder: (context, sIndex) {
                                    final sched = _selectedLoanDetails!['schedules'][sIndex];
                                    final double due = double.parse(sched['total_due'].toString());
                                    final double paid = double.parse(sched['amount_paid'].toString());
                                    final double outstanding = due - paid;
                                    final sStatus = sched['status'];
                                    
                                    return Container(
                                      color: sStatus == 'ROLLED_OVER' 
                                          ? Colors.red.withOpacity(0.05) 
                                          : sStatus == 'PAID' 
                                              ? Colors.green.withOpacity(0.02)
                                              : null,
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        title: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text('#${sched['installment_no']}')),
                                            Expanded(
                                              flex: 3, 
                                              child: Text(sched['due_date']),
                                            ),
                                            Expanded(
                                              flex: 3, 
                                              child: Text(
                                                currencyFormatter.format(outstanding),
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontWeight: outstanding > 0 ? FontWeight.bold : FontWeight.normal,
                                                  color: outstanding > 0 ? Colors.white : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3, 
                                              child: Text(
                                                sStatus == 'ROLLED_OVER' 
                                                    ? (ln.isTelugu ? 'రోల్‌ఓవర్' : 'ROLLED OVER') 
                                                    : sStatus == 'PARTIALLY_PAID'
                                                        ? (ln.isTelugu ? 'సగం చెల్లింపు' : 'PARTIAL')
                                                        : sStatus == 'PAID'
                                                            ? (ln.isTelugu ? 'చెల్లించబడింది' : 'PAID')
                                                            : (ln.isTelugu ? 'గడువు ఉంది' : 'PENDING'),
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  color: sStatus == 'ROLLED_OVER' 
                                                      ? Colors.red 
                                                      : sStatus == 'PAID' 
                                                          ? Colors.green 
                                                          : Colors.orange,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: status == 'PENDING'
                                      ? isAdmin
                                          ? ElevatedButton(
                                              onPressed: () => _approveLoan(loanId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.primary,
                                              ),
                                              child: Text(ln.translate('approve_loan')),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8)
                                              ),
                                              child: Text(
                                                ln.isTelugu 
                                                    ? 'రుణం ఆమోదం కోసం పెండింగ్‌లో ఉంది' 
                                                    : 'This loan is pending approval from Admin.',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontStyle: FontStyle.italic),
                                              ),
                                            )
                                      : status == 'ACTIVE' || status == 'DEFAULTED'
                                          ? ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => CollectPaymentScreen(
                                                      loanId: loanId,
                                                      borrowerName: '${_borrower!['first_name_en']} ${_borrower!['last_name_en']}',
                                                      languageNotifier: ln,
                                                    ),
                                                  ),
                                                ).then((_) => _fetchDetails());
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              child: Text(ln.translate('collect_payment')),
                                            )
                                          : const SizedBox.shrink(),
                                )
                              ]
                            ]
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSummaryMetrics(LanguageNotifier ln) {
    if (_selectedLoanDetails == null) return const SizedBox.shrink();
    
    final double principal = double.parse(_selectedLoanDetails!['principal_amount'].toString());
    final double totalRepayable = double.parse(_selectedLoanDetails!['total_repayable_amount'].toString());
    
    final schedules = _selectedLoanDetails!['schedules'] as List;
    final double totalPaid = schedules.fold(0.0, (sum, item) => sum + double.parse(item['amount_paid'].toString()));
    final double remaining = totalRepayable - totalPaid;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white.withOpacity(0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(ln.isTelugu ? 'మొత్తం అసలు' : 'Principal', currencyFormatter.format(principal)),
          _buildMetricItem(ln.translate('total_collected'), currencyFormatter.format(totalPaid)),
          _buildMetricItem(ln.translate('outstanding_balance'), currencyFormatter.format(remaining), highlight: true),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold,
            color: highlight ? Theme.of(context).colorScheme.primary : Colors.white,
          ),
        ),
      ],
    );
  }
}
