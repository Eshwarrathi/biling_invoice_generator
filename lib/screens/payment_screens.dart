import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';

class PaymentsScreen extends StatefulWidget {
  final String currentUserId; // logged-in user ID
  const PaymentsScreen({super.key, required this.currentUserId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  bool useFirebase = true;

  static const Color primary = Color(0xFF0B1B3A); // Deep Navy
  static const Color accent = Color(0xFF00C2A8);  // Teal Accent

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      List<Map<String, dynamic>> data = [];
      if (useFirebase) {
        data = await FirebaseService.getAllRecords('payments');
      }
      // Filter by current user
      setState(() => payments = data.where((p) => p['userId'] == widget.currentUserId).toList());
    } catch (e) {
      debugPrint('⚠️ Error loading payments: $e');
    }
  }

  void _clearControllers() {
    idController.clear();
    receiverController.clear();
    amountController.clear();
  }

  Future<void> _savePayment({Map<String, dynamic>? existing, int? index}) async {
    final id = idController.text.trim();
    final receiver = receiverController.text.trim();
    final amount = amountController.text.trim();

    if (id.isEmpty || receiver.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Fill all fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final record = {
      'userId': widget.currentUserId, // assign current user
      'paymentId': id,
      'receiver': receiver,
      'amount': amount,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      if (existing != null && existing['id'] != null) {
        await FirebaseService.updateRecord('payments', existing['id'], record);
      } else {
        await FirebaseService.addRecord('payments', record);
      }

      _clearControllers();
      Navigator.pop(context);
      _loadPayments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing != null ? '✅ Payment updated!' : '✅ Payment added!'),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePayment(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        title: const Text('Delete Payment', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete payment to "${record['receiver']}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (record['id'] != null) await FirebaseService.deleteRecord('payments', record['id']);
      _loadPayments();
    } catch (e) {
      debugPrint('⚠️ Error deleting payment: $e');
    }
  }

  void _showPaymentDialog({Map<String, dynamic>? record}) {
    if (record != null) {
      idController.text = record['paymentId'] ?? '';
      receiverController.text = record['receiver'] ?? '';
      amountController.text = record['amount'] ?? '';
    } else {
      _clearControllers();
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
                Text(record == null ? '💵 Add Payment' : '✏️ Edit Payment',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                _buildField(idController, 'Payment ID'),
                _buildField(receiverController, 'Receiver Name'),
                _buildField(amountController, 'Amount', isNumber: true),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => _savePayment(existing: record),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(record == null ? 'Add' : 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                )
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
        enabledBorder:
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      ),
    ),
  );

  Widget _paymentCard(Map<String, dynamic> record) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.payment, color: primary)),
      title: Text(record['receiver'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text('Amount: ${record['amount']}', style: const TextStyle(color: Colors.white70)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showPaymentDialog(record: record)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletePayment(record)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('💵 Payments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text('💾', style: TextStyle(color: Colors.white)),
              Switch(value: useFirebase, onChanged: (v) { setState(() => useFirebase = v); _loadPayments(); }, activeColor: Colors.white),
              const Text('☁️', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: payments.isEmpty
          ? const Center(
        child: Text("No payments found. Tap + to add one.",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (_, i) => _paymentCard(payments[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showPaymentDialog(),
      ),
    );
  }
}
