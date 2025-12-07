import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';
import 'sales_screen.dart';

class SummaryScreen extends StatefulWidget {
  final String currentUserId;
  const SummaryScreen({super.key, required this.currentUserId});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}
class _SummaryScreenState extends State<SummaryScreen> {
  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  bool useFirebase = true;
  bool loading = true;
  double totalPurchases = 0;
  double totalSales = 0;
  int totalItemsPurchased = 0;
  int totalItemsSold = 0;
  double totalExpenses = 0;
  double totalSalaries = 0;
  double totalPayments = 0;
  double profitLoss = 0;

  @override
  void initState() {
    super.initState();
    _calculateSummary();
  }
  // -------------------------
  // CALCULATE SUMMARY
  // -------------------------
  Future<void> _calculateSummary() async {
    setState(() => loading = true);

    try {
      List<Map<String, dynamic>> purchases = [];
      List<Map<String, dynamic>> sales = [];
      List<Map<String, dynamic>> expenses = [];
      List<Map<String, dynamic>> salaries = [];
      List<Map<String, dynamic>> payments = [];

      if (useFirebase) {
        purchases = await FirebaseService.getAllRecords('purchases');
        sales = await FirebaseService.getAllRecords('sales');
        expenses = await FirebaseService.getAllRecords('expenses');
        salaries = await FirebaseService.getAllRecords('salaries');
        payments = await FirebaseService.getAllRecords('payments');
      } else {
        purchases = LocalDBService.getAllRecords('purchases');
        sales = LocalDBService.getAllRecords('sales');
        expenses = LocalDBService.getAllRecords('expenses');
        salaries = LocalDBService.getAllRecords('salaries');
        payments = LocalDBService.getAllRecords('payments');
      }

      // Filter by current user
      purchases = purchases.where((e) => e['userId'] == widget.currentUserId).toList();
      sales = sales.where((e) => e['userId'] == widget.currentUserId).toList();
      expenses = expenses.where((e) => e['userId'] == widget.currentUserId).toList();
      salaries = salaries.where((e) => e['userId'] == widget.currentUserId).toList();
      payments = payments.where((e) => e['userId'] == widget.currentUserId).toList();

      // -------------------------
      // TOTAL PURCHASES
      // -------------------------
      totalPurchases = 0;
      totalItemsPurchased = 0;
      for (var e in purchases) {
        final price = double.tryParse(e['price']?.toString() ?? '0') ?? 0;
        final qty = int.tryParse(e['quantity']?.toString() ?? '0') ?? 0;
        totalPurchases += price * qty;
        totalItemsPurchased += qty;
      }

      // -------------------------
      // TOTAL SALES
      // -------------------------
      totalSales = 0;
      totalItemsSold = 0;
      for (var e in sales) {
        final price = double.tryParse(e['price']?.toString() ?? '0') ?? 0;
        final qty = int.tryParse(e['quantity']?.toString() ?? '0') ?? 0;
        totalSales += price * qty;
        totalItemsSold += qty;
      }

      // -------------------------
      // OTHERS
      // -------------------------
      totalExpenses = expenses.fold(
          0, (sum, e) => sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0));
      totalSalaries = salaries.fold(
          0,
              (sum, e) =>
          sum +
              (double.tryParse(e['baseSalary']?.toString() ?? '0') ?? 0) +
              (double.tryParse(e['extraPay']?.toString() ?? '0') ?? 0) -
              (double.tryParse(e['deduction']?.toString() ?? '0') ?? 0));
      totalPayments = payments.fold(
          0, (sum, e) => sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0));

      profitLoss = totalSales - totalPurchases - totalExpenses - totalSalaries - totalPayments;

      setState(() => loading = false);
    } catch (e) {
      debugPrint('⚠️ Error calculating summary: $e');
      setState(() => loading = false);
    }
  }

  // -------------------------
  // CARD WIDGET
  // -------------------------
  Widget _buildCard(String title, dynamic value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            value is double ? 'PKR ${value.toStringAsFixed(2)}' : value.toString(),
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // NAVIGATION WITH REFRESH
  // -------------------------
  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _calculateSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title:
        const Text('📊 Financial Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text('💾', style: TextStyle(color: Colors.white)),
              Switch(
                value: useFirebase,
                onChanged: (val) {
                  setState(() => useFirebase = val);
                  _calculateSummary();
                },
                activeColor: Colors.white,
              ),
              const Text('☁️', style: TextStyle(color: Colors.white)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _calculateSummary),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildCard('Total Purchases', totalPurchases),
          _buildCard('Items Purchased', totalItemsPurchased),
          _buildCard('Total Sales', totalSales),
          _buildCard('Items Sold', totalItemsSold),
          _buildCard('Total Expenses', totalExpenses),
          _buildCard('Total Salaries Paid', totalSalaries),
          _buildCard('Total Payments', totalPayments),
          _buildCard(
            profitLoss >= 0 ? 'Profit' : 'Loss',
            profitLoss.abs(),
            valueColor: profitLoss >= 0 ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Example: Navigate to SalesScreen (or PurchaseScreen) and refresh summary after returning
          // await _navigateAndRefresh(PurchaseScreen(currentUserId: widget.currentUserId));
          // await _navigateAndRefresh(SalesScreen(currentUserId: widget.currentUserId));
          _calculateSummary();
        },
        label: const Text("Refresh Summary"),
        icon: const Icon(Icons.refresh),
        backgroundColor: accent,
      ),
    );
  }
}
