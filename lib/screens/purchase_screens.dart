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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading purchases: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        const SnackBar(
            content: Text('⚠️ User not logged in'),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    final userId = user.uid;

    // Validate input
    if (itemController.text.isEmpty || quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Please fill all required fields'),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityController.text);
    final price = double.tryParse(priceController.text);

    if (quantity == null || price == null || quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Quantity and Price must be positive numbers'),
            backgroundColor: Colors.red
        ),
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

      // Close dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(record == null ? '✅ Purchase added!' : '✅ Purchase updated!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red
        ),
      );
    }
  }

  void _showRecordDialog({Map<String, dynamic>? record}) {
    if (record != null) {
      itemController.text = record['item'] ?? '';
      quantityController.text = record['quantity']?.toString() ?? '';
      priceController.text = record['price']?.toString() ?? '';
      supplierController.text = record['supplier'] ?? '';
    } else {
      _clearControllers();
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
                Text(
                  record == null ? '🧾 Add Purchase' : '✏️ Update Purchase',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 18),
                _buildField(itemController, 'Item', TextInputType.text),
                _buildField(quantityController, 'Quantity', TextInputType.number),
                _buildField(priceController, 'Price', TextInputType.numberWithOptions(decimal: true)),
                _buildField(supplierController, 'Supplier', TextInputType.text),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearControllers();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => _savePurchase(record: record),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primary
                      ),
                      child: Text(record == null ? 'Save' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, TextInputType keyboardType) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white30)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white)
        ),
      ),
    ),
  );

  Future<void> _deletePurchase(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        title: const Text('Delete Purchase', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${record['item']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (record['id'] != null) {
        await FirebaseService.deleteRecord('purchases', record['id']);
      }
      _loadPurchases();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Purchase "${record['item']}" deleted'),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting purchase: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _purchaseCard(Map<String, dynamic> record) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, accent]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ListTile(
      leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.shopping_cart, color: primary)
      ),
      title: Text(
          record['item'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      subtitle: Text(
        "Qty: ${record['quantity']} | Price: \$${record['price']} | Supplier: ${record['supplier'] ?? 'N/A'}",
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showRecordDialog(record: record)
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deletePurchase(record),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        title: const Text(
            "🛒 Purchases",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPurchases,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : purchases.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            const Text(
              "No purchase records yet.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap the + button to add your first purchase",
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPurchases,
        backgroundColor: primary,
        color: accent,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (_, i) => _purchaseCard(purchases[i]),
        ),
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