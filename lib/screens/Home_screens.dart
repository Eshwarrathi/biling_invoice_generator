import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_rules.dart';
import 'purchase_screens.dart';
import 'sales_screen.dart';
import 'expence_screen.dart';
import 'HR_mangement.dart';
import 'salary_screen.dart';
import 'payment_screens.dart';
import 'debit_credit.dart';
import 'calculate_summary.dart';
import 'pdf.dart';
import 'Dashboard.dart';
import 'stock_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  // Helper method to get current user ID
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    // Define all possible buttons with proper user ID
    final List<_HomeButton> allButtons = [
      _HomeButton('Purchase', Icons.shopping_cart, const PurchaseScreen()),
      _HomeButton('Sales', Icons.sell, const SalesScreen()),
      _HomeButton('Expenses', Icons.money_off, ExpensesScreen(currentUserId: currentUserId)),
      _HomeButton('HR Management', Icons.groups, HRScreen(currentUserId: currentUserId)),
      _HomeButton('Payments', Icons.payment, PaymentsScreen(currentUserId: currentUserId)),
      _HomeButton('Credit / Debit', Icons.account_balance_wallet, CreditDebitScreen(currentUserId: currentUserId)),
      _HomeButton('Calculation', Icons.calculate, SummaryScreen(currentUserId: currentUserId)),
      _HomeButton('PDF Export', Icons.picture_as_pdf, PdfExportScreen(currentUserId: currentUserId)),
      _HomeButton('Dashboard', Icons.dashboard, const DashboardScreen()),
      _HomeButton('Stock', Icons.storage, const StockScreen()),
      _HomeButton('Salary', Icons.attach_money, const SalaryScreen(useFirebase: true)),
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
        actions: [
          // User role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C2A8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00C2A8), width: 1),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Role info button
          PopupMenuButton<String>(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'role_info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role: ${role.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AccessRules.getRoleDescriptions()[role] ?? 'No description available',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'role_info') {
                // Show role information
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AccessRules.getRoleDescriptions()[role] ?? 'No description available',
                    ),
                    duration: const Duration(seconds: 3),
                    backgroundColor: const Color(0xFF00C2A8),
                  ),
                );
              }
            },
          ),

          const SizedBox(width: 10),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: buttonsToShow.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              'No Access Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your role "$role" does not have access to any features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C2A8),
                foregroundColor: const Color(0xFF0B1B3A),
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Welcome message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B1B3A),
                  const Color(0xFF0B1B3A).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Welcome to Recora',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Role: ${role.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00C2A8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Available Features: ${buttonsToShow.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Features grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                itemCount: buttonsToShow.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.9,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              btn.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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