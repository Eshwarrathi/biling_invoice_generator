import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

class ExpensesScreen extends StatefulWidget {
  final String currentUserId; // Pass the logged-in user ID
  const ExpensesScreen({super.key, required this.currentUserId});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map<String, dynamic>> expenses = [];
  bool useFirebase = true;
  bool isLoading = false;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];
      if (useFirebase) {
        data = await FirebaseService.getAllRecords('expenses');
      } else {
        final local = LocalDBService.getAllRecords('expenses');
        data = local.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Filter by current user
      data = data.where((record) => record['userId'] == widget.currentUserId).toList();

      setState(() => expenses = data);
    } catch (e) {
      debugPrint('⚠️ Error loading expenses: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearControllers() {
    reasonController.clear();
    amountController.clear();
  }

  Future<void> _saveExpense({String? id, int? localIndex}) async {
    if (reasonController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Fill all fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final record = {
      'userId': widget.currentUserId, // attach current user
      'reason': reasonController.text,
      'amount': amountController.text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      if (id != null && id.isNotEmpty) {
        // UPDATE
        if (useFirebase) await FirebaseService.updateRecord('expenses', id, record);
        if (localIndex != null) await LocalDBService.updateRecord('expenses', localIndex, record);
      } else {
        // ADD
        if (useFirebase) await FirebaseService.addRecord('expenses', record);
        await LocalDBService.saveRecord('expenses', record);
      }

      _clearControllers();
      Navigator.pop(context);
      _loadExpenses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Expense saved!', style: TextStyle(color: Colors.white)),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${record['reason']}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (useFirebase && record['id'] != null) await FirebaseService.deleteRecord('expenses', record['id']);
      final index = expenses.indexOf(record);
      await LocalDBService.deleteRecord('expenses', index);
      _loadExpenses();
    } catch (e) {
      debugPrint('⚠️ Error deleting expense: $e');
    }
  }

  void _showExpenseDialog({Map<String, dynamic>? record, int? localIndex}) {
    if (record != null) {
      reasonController.text = record['reason'] ?? '';
      amountController.text = record['amount'] ?? '';
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(record == null ? '💰 Add Expense' : '✏️ Edit Expense',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                _buildField(reasonController, 'Reason'),
                _buildField(amountController, 'Amount', isNumber: true),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => _saveExpense(id: record?['id'], localIndex: localIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(record == null ? 'Save' : 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, {bool isNumber = false}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      ),
    ),
  );

  Widget _expenseCard(Map<String, dynamic> record, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        title: Text(record['reason'] ?? 'Unknown Expense', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('Amount: ${record['amount']}', style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteExpense(record)),
        onTap: () => _showExpenseDialog(record: record, localIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('💰 Expenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(value: useFirebase, onChanged: (v) { setState(() => useFirebase = v); _loadExpenses(); }, activeThumbColor: Colors.white),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : expenses.isEmpty
          ? const Center(child: Text("No expenses recorded.", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: expenses.length, itemBuilder: (_, i) => _expenseCard(expenses[i], i)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showExpenseDialog(),
      ),
    );
  }
}
