import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool useFirebase = true;

  double totalCredit = 0;
  double totalDebit = 0;
  double totalExpenses = 0;

  static const Color primary = Color(0xFF0B1B3A); // Deep Navy
  static const Color accent = Color(0xFF00C2A8);  // Teal Accent

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<Map<String, dynamic>> creditDebitData = [];
      List<Map<String, dynamic>> expensesData = [];

      if (useFirebase) {
        creditDebitData = await FirebaseService.getAllRecords("credits_debits");
        expensesData = await FirebaseService.getAllRecords("expenses");
      } else {
        creditDebitData = LocalDBService.getAllRecords("credits_debits")
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        expensesData = LocalDBService.getAllRecords("expenses")
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // Calculate totals
      double creditSum = 0;
      double debitSum = 0;
      double expenseSum = 0;

      for (var i in creditDebitData) {
        double amount = double.tryParse(i['amount'].toString()) ?? 0;
        if (i['type'] == "credit") {
          creditSum += amount;
        } else if (i['type'] == "debit") {
          debitSum += amount;
        }
      }

      for (var e in expensesData) {
        double amount = double.tryParse(e['amount'].toString()) ?? 0;
        expenseSum += amount;
      }

      setState(() {
        totalCredit = creditSum;
        totalDebit = debitSum;
        totalExpenses = expenseSum;
      });

    } catch (e) {
      debugPrint("❌ Dashboard Error: $e");
    }
  }

  Widget _summaryCard(String title, String value, Color valueColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double finalBalance = totalCredit - totalDebit - totalExpenses;

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("📊 Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(
                value: useFirebase,
                onChanged: (v) {
                  setState(() => useFirebase = v);
                  _loadData();
                },
                activeThumbColor: Colors.white,
              ),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard("Total Credit", "Rs $totalCredit", Colors.greenAccent),
            _summaryCard("Total Debit", "Rs $totalDebit", Colors.redAccent),
            _summaryCard("Total Expenses", "Rs $totalExpenses", Colors.orangeAccent),
            _summaryCard(
              "Final Balance",
              "Rs $finalBalance",
              finalBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
              ),
              onPressed: _loadData,
              child: const Text(
                "Refresh Data",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
