import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

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
      setState(() {
        _borrowers = list;
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
                          : ListView.builder(
                              itemCount: _borrowers.length,
                              itemBuilder: (context, index) {
                                final borrower = _borrowers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      '${borrower['first_name_en']} ${borrower['last_name_en']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(borrower['phone_number']),
                                    trailing: const Icon(Icons.chevron_right),
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
}
