import 'package:biling_invoice_generator/screens/login_screens.dart';
import 'package:biling_invoice_generator/screens/splash_screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/Home_screens.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey=""
      "pk_test_51SUlFUPgKCJMoZHLlGZp2PqWScaVaRiRZd7fs40xdTNq2ClFpvmp2b0MeOiXF1GI88y3h8KLx38QkAS4KngSpSjx00LQfzFTt5";
  // ✅ Initialize Firebase
  await Firebase.initializeApp();
  // ✅ Initialize Hive (local DB)
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  // ✅ Open Hive Boxes (for offline tables)
  await Hive.openBox('purchases');
  await Hive.openBox('sales');
  await Hive.openBox('auth');
  await Hive.openBox('expenses');
  await Hive.openBox('payments');
  await Hive.openBox('employees');
  await Hive.openBox('SummaryScreen');
  await Hive.openBox("Debit_credit");
  await Hive.openBox("Dashboard");
  await Hive.openBox("Pdf");


  // 🧑‍💼 HR Employees
  await Hive.openBox('salaries');  // 💰 Salary Records
  // ✅ Run App
  runApp(const RecordKeeperApp());
}
class RecordKeeperApp extends StatelessWidget {
  const RecordKeeperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Record Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: SplashScreen(),

      // 👋 You can show splash before home
    );
  }
}
