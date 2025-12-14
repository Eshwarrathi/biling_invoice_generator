import 'package:biling_invoice_generator/screens/splash_screens.dart';
import 'package:biling_invoice_generator/screens/login_screens.dart';
import 'package:biling_invoice_generator/screens/register_screens.dart'; // ✅ RegisterScreen import
import 'package:biling_invoice_generator/screens/forget_password.dart'; // ✅ ForgetPasswordScreen import
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Stripe Setup
  Stripe.publishableKey = "pk_test_51SUlFUPgKCJMoZHLlGZp2PqWScaVaRiRZd7fs40xdTNq2ClFpvmp2b0MeOiXF1GI88y3h8KLx38QkAS4KngSpSjx00LQfzFTt5";
  await Stripe.instance.applySettings();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Initialize Hive (local DB)
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // ✅ Open ALL Hive Boxes (for offline tables)
  await Hive.openBox('purchases');
  await Hive.openBox('sales');
  await Hive.openBox('auth');
  await Hive.openBox('expenses');
  await Hive.openBox('payments');
  await Hive.openBox('employees');
  await Hive.openBox('salaries');
  await Hive.openBox('credits_debits');

  // ✅ Additional boxes for other features
  await Hive.openBox('dashboard_data');
  await Hive.openBox('pdf_data');
  await Hive.openBox('summary_data');
  await Hive.openBox('settings');

  // ✅ Run App
  runApp(const RecordKeeperApp());
}

class RecordKeeperApp extends StatelessWidget {
  const RecordKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recora - Record Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00C2A8), // Teal accent color
        scaffoldBackgroundColor: const Color(0xFF0B1B3A), // Primary color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1B3A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00C2A8), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C2A8),
            foregroundColor: const Color(0xFF0B1B3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) {
          // Get role from arguments
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HomeScreen(role: args?['role'] ?? 'user');
        },
        '/register': (context) => const RegisterScreen(), // ✅ Fixed
      },
      onGenerateRoute: (settings) {
        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFF0B1B3A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Page Not Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The requested page does not exist.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}