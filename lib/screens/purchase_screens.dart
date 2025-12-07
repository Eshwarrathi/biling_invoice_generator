import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_servicves.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();

  List<Map<String, dynamic>> purchases = [];
  bool isLoading = false;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => isLoading = true);
    try {
      final data = await FirebaseService.getMyRecords('purchases');
      setState(() => purchases = data);
    } catch (e) {
      debugPrint('⚠️ Error loading purchases: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearControllers() {
    itemController.clear();
    quantityController.clear();
    priceController.clear();
    supplierController.clear();
  }
  Future<void> _savePurchase({Map<String, dynamic>? record}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ User not logged in'), backgroundColor: Colors.red),
      );
      return;
    }

    final userId = user.uid;

    // Validate input
    if (itemController.text.isEmpty || quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    final quantity = int.tryParse(quantityController.text);
    final price = double.tryParse(priceController.text);

    if (quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Quantity and Price must be numbers'), backgroundColor: Colors.red),
      );
      return;
    }

    // Prepare record with correct userId
    final newRecord = {
      'item': itemController.text.trim(),
      'quantity': quantity,
      'price': price,
      'supplier': supplierController.text.trim(),
      'userId': userId, // ✅ Must match Firestore rules
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      if (record != null && record['id'] != null) {
        final success = await FirebaseService.updateRecord('purchases', record['id'], newRecord);
        if (!success) throw Exception('❌ Permission denied or update failed');
      } else {
        await FirebaseService.addRecord('purchases', newRecord);
      }

      _clearControllers();
      _loadPurchases();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(record == null ? '✅ Purchase added!' : '✅ Purchase updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }




  void _showRecordDialog({Map<String, dynamic>? record}) {
    if (record != null) {
      itemController.text = record['item'] ?? '';
      quantityController.text = record['quantity']?.toString() ?? '';
      priceController.text = record['price']?.toString() ?? '';
      supplierController.text = record['supplier'] ?? '';
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, accent]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(record == null ? '🧾 Add Purchase' : '✏️ Update Purchase',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                _buildField(itemController, 'Item'),
                _buildField(quantityController, 'Quantity'),
                _buildField(priceController, 'Price'),
                _buildField(supplierController, 'Supplier'),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => _savePurchase(record: record),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primary),
                  child: Text(record == null ? 'Save' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
    ),
  );

  Widget _purchaseCard(Map<String, dynamic> record) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, accent]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.shopping_cart, color: primary)),
      title: Text(record['item'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("Qty: ${record['quantity']} | Price: ${record['price']}", style: const TextStyle(color: Colors.white70)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showRecordDialog(record: record)),
        IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              if (record['id'] != null) await FirebaseService.deleteRecord('purchases', record['id']);
              _loadPurchases();
            }),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
          title: const Text("🛒 Purchases", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primary,
          elevation: 0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : purchases.isEmpty
          ? const Center(child: Text("No records yet.", style: TextStyle(color: Colors.white70)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (_, i) => _purchaseCard(purchases[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Purchase", style: TextStyle(color: Colors.white)),
        onPressed: () => _showRecordDialog(),
      ),
    );
  }
}
