import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';
import 'ui_pdf.dart'; // PdfService + ReportType

class PdfExportScreen extends StatefulWidget {
  final String currentUserId; // logged-in user
  const PdfExportScreen({super.key, required this.currentUserId});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  bool useFirebase = true;
  String selectedPdf = "Finance";

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  double totalCredit = 0;
  double totalDebit = 0;
  double totalExpenses = 0;
  double finalBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    if (selectedPdf != "Finance") return;

    List<Map<String, dynamic>> cd = [];
    List<Map<String, dynamic>> exp = [];

    if (useFirebase) {
      cd = await FirebaseService.getAllRecords("credits_debits");
      exp = await FirebaseService.getAllRecords("expenses");
    } else {
      cd = LocalDBService.getAllRecords("credits_debits")
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      exp = LocalDBService.getAllRecords("expenses")
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // Filter by current user
    cd = cd.where((e) => e['userId'] == widget.currentUserId).toList();
    exp = exp.where((e) => e['userId'] == widget.currentUserId).toList();

    double credit = 0, debit = 0, expense = 0;

    for (var r in cd) {
      double amt = double.tryParse(r["amount"].toString()) ?? 0;
      if (r["type"] == "credit") credit += amt;
      if (r["type"] == "debit") debit += amt;
    }

    for (var r in exp) {
      expense += double.tryParse(r["amount"].toString()) ?? 0;
    }

    setState(() {
      totalCredit = credit;
      totalDebit = debit;
      totalExpenses = expense;
      finalBalance = credit - debit - expense;
    });
  }

  void _exportPdf() {
    PdfService.exportReportPdf(
      context,
      reportType: _getReportType(selectedPdf),
      filename: "${selectedPdf}_Report.pdf",
      useFirebase: useFirebase,
      currentUserId: widget.currentUserId,
    );
  }

  ReportType _getReportType(String selected) {
    switch (selected) {
      case "Finance":
        return ReportType.finance;
      case "Purchase":
        return ReportType.purchase;
      case "Sales":
        return ReportType.sales;
      case "Expenses":
        return ReportType.expense;
      case "Payments":
        return ReportType.payments;
      case "HR":
        return ReportType.hr;
      default:
        return ReportType.finance;
    }
  }

  Widget summaryCard(String title, String value, Color valueColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("📄 Export PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(
                value: useFirebase,
                activeThumbColor: Colors.white,
                onChanged: (v) {
                  setState(() => useFirebase = v);
                  _loadTotals();
                },
              ),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                initialValue: selectedPdf,
                decoration: const InputDecoration(
                  labelText: "Select PDF Type",
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                dropdownColor: primary,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: "Finance", child: Text("Finance Report")),
                  DropdownMenuItem(value: "Purchase", child: Text("Purchase Report")),
                  DropdownMenuItem(value: "Sales", child: Text("Sales Report")),
                  DropdownMenuItem(value: "Expenses", child: Text("Expenses Report")),
                  DropdownMenuItem(value: "Payments", child: Text("Payments Report")),
                  DropdownMenuItem(value: "HR", child: Text("HR Report")),
                ],
                onChanged: (v) {
                  setState(() {
                    selectedPdf = v!;
                    _loadTotals();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            if (selectedPdf == "Finance") ...[
              summaryCard("Total Credit", "Rs $totalCredit", Colors.greenAccent),
              summaryCard("Total Debit", "Rs $totalDebit", Colors.redAccent),
              summaryCard("Total Expenses", "Rs $totalExpenses", Colors.orangeAccent),
              summaryCard(
                "Final Balance",
                "Rs $finalBalance",
                finalBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text("Export $selectedPdf PDF",
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
