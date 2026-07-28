import 'package:flutter/material.dart';
import 'localization.dart';
import 'api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init(); // Initialize the Mock database and token manager
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageNotifier _languageNotifier = LanguageNotifier();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: _languageNotifier.translate('app_title'),
          debugShowCheckedModeBanner: false,
          
          // Premium Theme: Modern, sleek dark slate layout
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF6366F1), // Premium Indigo
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark slate
            
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFF8B5CF6), // Violet
              surface: Color(0xFF1E293B), // Slate 800
              background: Color(0xFF0F172A),
              error: Color(0xFFEF4444),
            ),
            
            fontFamily: 'Roboto',
            
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE2E8F0)),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
            
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
            
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          
          home: MainScreenGate(languageNotifier: _languageNotifier),
        );
      },
    );
  }
}

class MainScreenGate extends StatelessWidget {
  final LanguageNotifier languageNotifier;
  
  const MainScreenGate({super.key, required this.languageNotifier});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.token != null;
    
    return Scaffold(
      body: isLoggedIn 
          ? HomeScreen(languageNotifier: languageNotifier) 
          : LoginScreen(languageNotifier: languageNotifier),
    );
  }
}
