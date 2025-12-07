import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

class CreditDebitScreen extends StatefulWidget {
  final String currentUserId; // Logged-in user ID
  const CreditDebitScreen({super.key, required this.currentUserId});

  @override
  State<CreditDebitScreen> createState() => _CreditDebitScreenState();
}

class _CreditDebitScreenState extends State<CreditDebitScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String type = "credit"; // credit / debit

  List<Map<String, dynamic>> records = [];
  bool useFirebase = true;

  static const Color primary = Color(0xFF0B1B3A); // Deep Navy
  static const Color accent = Color(0xFF00C2A8);  // Teal Accent

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      List<Map<String, dynamic>> data = [];
      if (useFirebase) {
        data = await FirebaseService.getAllRecords('credits_debits');
      } else {
        final local = LocalDBService.getAllRecords('credits_debits');
        data = local.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      // Filter records by current user
      setState(() => records = data.where((r) => r['userId'] == widget.currentUserId).toList());
    } catch (e) {
      debugPrint("❌ Load Error: $e");
    }
  }

  void _clear() {
    titleController.clear();
    amountController.clear();
    type = "credit";
  }

  Future<void> _saveRecord({int? index, String? id}) async {
    if (titleController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final record = {
      "userId": widget.currentUserId, // Save current user ID
      "title": titleController.text,
      "amount": amountController.text,
      "type": type,
      "createdAt": DateTime.now().toIso8601String(),
    };

    try {
      if (index != null) {
        await LocalDBService.updateRecord('credits_debits', index, record);
        if (useFirebase && id != null) {
          await FirebaseService.updateRecord('credits_debits', id, record);
        }
      } else {
        if (useFirebase) {
          await FirebaseService.addRecord('credits_debits', record);
        }
        await LocalDBService.saveRecord('credits_debits', record);
      }

      _clear();
      Navigator.pop(context);
      _loadRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Saved successfully!"),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      debugPrint("❌ Save Error: $e");
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record, int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        title: const Text("Delete?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure to delete '${record['title']}'?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (useFirebase && record['id'] != null) {
        await FirebaseService.deleteRecord('credits_debits', record['id']);
      }
      await LocalDBService.deleteRecord('credits_debits', index);
      _loadRecords();
    } catch (e) {
      debugPrint("❌ Delete Error: $e");
    }
  }

  void _showDialog({Map<String, dynamic>? record, int? index}) {
    if (record != null) {
      titleController.text = record['title'] ?? "";
      amountController.text = record['amount'] ?? "";
      type = record['type'] ?? "credit";
    } else {
      _clear();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(record == null ? "➕ Add Entry" : "✏️ Edit Entry",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              _field(titleController, "Title"),
              _field(amountController, "Amount", number: true),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: "credit",
                    groupValue: type,
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const Text("Credit", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  Radio<String>(
                    value: "debit",
                    groupValue: type,
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const Text("Debit", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => _saveRecord(index: index, id: record?['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(record == null ? "Save" : "Update", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
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

  Widget _recordCard(Map<String, dynamic> record, int index) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: ListTile(
      title: Text(record["title"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("${record['type'].toUpperCase()} — Rs ${record['amount']}", style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteRecord(record, index)),
      onTap: () => _showDialog(record: record, index: index),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("💳 Credit / Debit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(
                value: useFirebase,
                onChanged: (v) { setState(() => useFirebase = v); _loadRecords(); },
                activeColor: Colors.white,
              ),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),
      body: records.isEmpty
          ? const Center(
        child: Text("No Credit/Debit records",
            style: TextStyle(fontSize: 16, color: Colors.white70)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (_, i) => _recordCard(records[i], i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
