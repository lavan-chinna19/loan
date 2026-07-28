import 'package:flutter/material.dart';
import '../localization.dart';
import '../api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final LanguageNotifier languageNotifier;
  
  const LoginScreen({super.key, required this.languageNotifier});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.languageNotifier.isTelugu 
            ? 'దయచేసి అన్ని వివరాలను నమోదు చేయండి' 
            : 'Please enter all credentials';
      });
      return;
    }

    final success = await ApiService.login(username, password);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(languageNotifier: widget.languageNotifier),
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.languageNotifier.isTelugu 
              ? 'తప్పుడు యూజర్ నేమ్ లేదా పాస్‌వర్డ్' 
              : 'Invalid username or password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ln.translate('app_title')),
        actions: [
          TextButton(
            onPressed: () => ln.toggleLanguage(),
            child: Text(
              ln.isTelugu ? 'ENG' : 'తెలుగు',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              Text(
                ln.translate('login_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              
              Text(
                ln.translate('login_subtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: ln.translate('username'),
                  prefixIcon: const Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: ln.translate('password'),
                  prefixIcon: const Icon(Icons.lock),
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
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(ln.translate('login_button')),
              ),
              const SizedBox(height: 24),
              
              // Helper text for development
              Card(
                color: Colors.white.withOpacity(0.02),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'Demo Logins (Username : Password)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Admin: admin : admin123', style: TextStyle(fontSize: 11)),
                      Text('Collector: collector : collector123', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
