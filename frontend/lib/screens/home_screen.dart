import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization.dart';
import '../api_service.dart';
import 'login_screen.dart';
import 'borrower_detail_screen.dart';
import 'register_borrower_screen.dart';

class HomeScreen extends StatefulWidget {
  final LanguageNotifier languageNotifier;
  
  const HomeScreen({super.key, required this.languageNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _borrowers = [];
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;
  String? _errorMessage;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _fetchBorrowers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBorrowers([String? query]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getBorrowers(query: query);
      final stats = await ApiService.getDashboardStats();
      setState(() {
        _borrowers = list;
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.languageNotifier.isTelugu 
            ? 'వివరాలను లోడ్ చేయడంలో విఫలమైంది' 
            : 'Failed to load borrowers';
      });
    }
  }

  Future<void> _triggerRollovers() async {
    final ln = widget.languageNotifier;
    try {
      final count = await ApiService.triggerRollovers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ln.isTelugu 
                  ? 'రోల్‌ఓవర్‌లు విజయవంతంగా ప్రాసెస్ చేయబడ్డాయి. అప్‌డేట్ చేసిన వాయిదాలు: $count'
                  : 'Rollovers processed successfully. Rolled over $count installments.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchBorrowers(_searchController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ln.isTelugu ? 'రోల్‌ఓవర్ రన్ విఫలమైంది' : 'Failed to trigger rollovers.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(languageNotifier: widget.languageNotifier),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppReminder(Map<String, dynamic> borrower, double _totalOutstanding) async {
    final ln = widget.languageNotifier;
    var phone = borrower['phone_number'].toString().replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10) phone = '91$phone';

    final name = ln.isTelugu && borrower['name_te'] != null && borrower['name_te'].toString().trim().isNotEmpty
        ? borrower['name_te']
        : '${borrower['first_name_en']}';
    final borrowerId = borrower['id'];
    
    // Calculate current monthly installment amount
    double interestAmount = 0.0;
    try {
      final loans = await ApiService.getBorrowerLoans(borrowerId);
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      for (var loan in loans) {
        if (loan['status'] == 'ACTIVE' || loan['status'] == 'DEFAULTED') {
          final details = await ApiService.getLoanDetails(loan['id']);
          final schedules = details['schedules'] as List;
          
          bool foundFuture = false;
          for (var sched in schedules) {
            if (sched['status'] != 'PAID') {
              final unpaid = double.parse(sched['total_due'].toString()) - double.parse(sched['amount_paid'].toString());
              final dueDate = sched['due_date'].toString();
              if (dueDate.compareTo(nowStr) <= 0) {
                interestAmount += unpaid;
              } else if (interestAmount == 0.0 && !foundFuture) {
                interestAmount += unpaid;
                foundFuture = true;
              }
            }
          }
        }
      }
    } catch (_) {}

    if (interestAmount <= 0) {
      interestAmount = _totalOutstanding; // Fallback if no specific schedules are found but there's a balance
    }

    final formattedAmount = currencyFormatter.format(interestAmount);
    
    final String message = ln.isTelugu 
        ? 'నమస్కారం $name గారు, మీ లోన్ ఖాతాకు సంబంధించి ఈ నెల వడ్డీ రూపాయిలు $formattedAmount చెల్లించవలసి ఉంది. దయచేసి వీలైనంత త్వరగా చెల్లించగలరు. ధన్యవాదాలు.'
        : 'Hello $name, This is a friendly reminder that your monthly interest payment of $formattedAmount is currently due. Please arrange to pay at your earliest convenience. Thank you.';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback to web URL
        final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch WhatsApp');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ln.isTelugu ? 'వాట్సాప్ ఓపెన్ చేయడం సాధ్యపడలేదు' : 'Could not launch WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;
    final isAdmin = ApiService.userRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(ln.translate('dashboard')),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _handleLogout,
          tooltip: ln.translate('logout'),
        ),
        actions: [
          TextButton(
            onPressed: () => ln.toggleLanguage(),
            child: Text(
              ln.isTelugu ? 'ENG' : 'తెలుగు',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Agent Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 24,
                      child: Text(
                        (ApiService.userName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ln.isTelugu 
                                ? 'నమస్కారం, ${ApiService.userName}' 
                                : 'Welcome, ${ApiService.userName}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            ln.isTelugu 
                                ? 'పాత్ర: ${ApiService.userRole == 'ADMIN' ? 'అడ్మిన్' : 'వసూలు కలెక్టర్'}' 
                                : 'Role: ${ApiService.userRole}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _triggerRollovers,
                        tooltip: ln.translate('trigger_rollovers'),
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_dashboardStats != null) ...[
              _buildDashboardMetricsCard(ln),
              const SizedBox(height: 16),
            ],
            
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: ln.translate('search_borrower_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchBorrowers();
                  },
                ),
              ),
              onChanged: (val) {
                _fetchBorrowers(val.trim());
              },
            ),
            const SizedBox(height: 16),
            
            // Borrowers list title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ln.translate('borrowers'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_borrowers.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Borrowers list view
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _borrowers.isEmpty
                          ? Center(
                              child: Text(
                                ln.isTelugu 
                                    ? 'ఎలాంటి రికార్డులు లేవు' 
                                    : 'No borrowers found',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchBorrowers(_searchController.text.trim()),
                              child: ListView.builder(
                                itemCount: _borrowers.length,
                                itemBuilder: (context, index) {
                                  final borrower = _borrowers[index];
                                  final hasLoan = borrower['has_loan'] == true;
                                  final loanModel = borrower['latest_loan_model'] == 'MODEL_A' 
                                      ? 'Model A' 
                                      : borrower['latest_loan_model'] == 'MODEL_B' 
                                          ? 'Model B' 
                                          : null;
                                  final outstanding = borrower['latest_outstanding'] as double? ?? 0.0;
                                  final status = borrower['latest_loan_status']?.toString();

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Row(
                                        children: [
                                          Text(
                                            '${borrower['first_name_en']} ${borrower['last_name_en']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          if (hasLoan && loanModel != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (status == 'ACTIVE' ? Colors.green : Colors.orange).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$loanModel (${status ?? ''})',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: status == 'ACTIVE' ? Colors.green : Colors.orange,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('${borrower['phone_number']} ${borrower['address_en'] != null ? '• ${borrower['address_en']}' : ''}'),
                                          if (hasLoan && outstanding > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                '${ln.isTelugu ? 'చెల్లించాల్సింది:' : 'Due:'} ${currencyFormatter.format(outstanding)}',
                                                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ),
                                          if (hasLoan && outstanding <= 0 && status == 'FULLY_PAID')
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                ln.isTelugu ? 'పూర్తిగా చెల్లించబడింది' : 'Fully Paid',
                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (hasLoan && outstanding > 0)
                                            IconButton(
                                              icon: const Icon(Icons.wechat, color: Colors.green),
                                              tooltip: ln.isTelugu ? 'వాట్సాప్ రిమైండర్' : 'WhatsApp Reminder',
                                              onPressed: () => _sendWhatsAppReminder(borrower, outstanding),
                                            ),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BorrowerDetailScreen(
                                              borrowerId: borrower['id'],
                                              languageNotifier: widget.languageNotifier,
                                            ),
                                          ),
                                        ).then((_) => _fetchBorrowers(_searchController.text.trim()));
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RegisterBorrowerScreen(languageNotifier: ln),
            ),
          ).then((_) => _fetchBorrowers());
        },
        tooltip: ln.translate('register_borrower'),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildDashboardMetricsCard(LanguageNotifier ln) {
    final stats = _dashboardStats!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  ln.isTelugu ? 'రుణాల పోర్ట్‌ఫోలియో సారాంశం' : 'Portfolio Overview (Live Storage)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  ln.isTelugu ? 'యాక్టివ్ రుణాలు' : 'Active Loans',
                  '${stats['active_loans_count']}',
                  Icons.real_estate_agent,
                ),
                _buildStatItem(
                  ln.isTelugu ? 'వసూలైనది' : 'Total Collected',
                  currencyFormatter.format(stats['total_collected']),
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _buildStatItem(
                  ln.isTelugu ? 'బకాయిలు' : 'Outstanding',
                  currencyFormatter.format(stats['total_outstanding']),
                  Icons.pending_actions,
                  color: stats['total_outstanding'] > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
