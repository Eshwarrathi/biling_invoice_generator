import 'package:flutter/material.dart';
import '../services/access_rules.dart';
import 'purchase_screens.dart';
import 'sales_screen.dart';
import 'expence_screen.dart';
import 'HR_mangement.dart';
import 'payment_screens.dart';
import 'debit_credit.dart';
import 'calculate_summary.dart';
import 'pdf.dart';
import 'Dashboard.dart';
import 'stock_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Define all possible buttons
    final List<_HomeButton> allButtons = [
      _HomeButton('Purchase', Icons.shopping_cart, const PurchaseScreen()),
      _HomeButton('Sales', Icons.sell, const SalesScreen()),
      _HomeButton('Expenses', Icons.money_off, const ExpensesScreen(currentUserId: '',)),
      _HomeButton('HR Management', Icons.groups, const HRScreen(currentUserId: '',)),
      _HomeButton('Payments', Icons.payment, const PaymentsScreen(currentUserId: '',)),
      _HomeButton('Credit / Debit', Icons.account_balance_wallet, const CreditDebitScreen(currentUserId: '',)),
      _HomeButton('Calculation', Icons.calculate, const SummaryScreen(currentUserId: '',)),
      _HomeButton('PDF Export', Icons.picture_as_pdf, const PdfExportScreen(currentUserId: '',)),
      _HomeButton('Dashboard', Icons.dashboard, const DashboardScreen()),
      _HomeButton('Stock', Icons.storage, const StockScreen()),
    ];

    // Filter buttons based on the user's role
    final buttonsToShow = allButtons
        .where((btn) => AccessRules.hasAccess(role, btn.title))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1B3A),
      appBar: AppBar(
        title: const Text('🏭 Recora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1B3A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: buttonsToShow.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
          ),
          itemBuilder: (context, index) {
            final btn = buttonsToShow[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => btn.screen),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1B3A), Color(0xFF00C2A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1B3A).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(btn.icon, size: 50, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      btn.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeButton {
  final String title;
  final IconData icon;
  final Widget screen;
  const _HomeButton(this.title, this.icon, this.screen);
}
