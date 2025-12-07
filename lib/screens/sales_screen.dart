import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

const String currentUserId = 'USER_123';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController customerController = TextEditingController();

  List<Map<String, dynamic>> sales = [];
  List<String> purchasedItems = []; // <-- for dropdown
  bool useFirebase = true;
  bool isLoading = false;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    _loadPurchasedItems();
    _loadSales();
  }

  // ---------------------------
  // LOAD PURCHASED ITEMS
  // ---------------------------
  Future<void> _loadPurchasedItems() async {
    final purchaseRecords = await FirebaseService.getAllRecords('purchases');
    setState(() {
      purchasedItems = purchaseRecords
          .where((r) => r['userId'] == currentUserId)
          .map<String>((r) => r['item'].toString())
          .toSet()
          .toList();
    });
  }

  // ---------------------------
  // LOAD SALES
  // ---------------------------
  Future<void> _loadSales() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];

      if (useFirebase) {
        final allRecords = await FirebaseService.getAllRecords('sales');
        data = allRecords.where((r) => r['userId'] == currentUserId).toList();
      } else {
        final local = LocalDBService.getAllRecords('sales');
        data = local
            .map((e) => Map<String, dynamic>.from(e))
            .where((r) => r['userId'] == currentUserId)
            .toList();
      }

      setState(() => sales = data);
    } catch (e) {
      debugPrint('⚠ Error loading sales: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearControllers() {
    itemController.clear();
    quantityController.clear();
    priceController.clear();
    customerController.clear();
  }

  // ---------------------------
  // STOCK CHECK SYSTEM
  // ---------------------------
  Future<int> getAvailableStock(String item, {Map<String, dynamic>? editingRecord}) async {
    int totalPurchased = 0;
    int totalSold = 0;

    // GET PURCHASE RECORDS
    final purchaseRecords = await FirebaseService.getAllRecords('purchases');
    for (var r in purchaseRecords) {
      if (r['userId'] == currentUserId && r['item'] == item) {
        totalPurchased += int.tryParse(r['quantity'].toString()) ?? 0;
      }
    }

    // GET SOLD RECORDS
    final salesRecords = await FirebaseService.getAllRecords('sales');
    for (var r in salesRecords) {
      if (r['userId'] == currentUserId && r['item'] == item) {
        totalSold += int.tryParse(r['quantity'].toString()) ?? 0;
      }
    }

    // If editing a record, add back its original quantity
    if (editingRecord != null) {
      totalSold -= int.tryParse(editingRecord['quantity'].toString()) ?? 0;
    }

    return totalPurchased - totalSold;
  }

  // ---------------------------
  // SAVE SALE
  // ---------------------------
  Future<void> _saveSale({String? id, int? index, Map<String, dynamic>? editingRecord}) async {
    // block unknown items
    if (!purchasedItems.contains(itemController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ This item is NOT in Purchases. Cannot sell it!',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠ Fill all fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityController.text);
    final price = double.tryParse(priceController.text);

    if (quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠ Quantity & Price must be numbers',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // -----------------------
    // STOCK VALIDATION CHECK
    // -----------------------
    int availableStock = await getAvailableStock(itemController.text, editingRecord: editingRecord);
    if (quantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⛔ Not enough stock!\nAvailable: $availableStock',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final record = {
      'item': itemController.text,
      'quantity': quantity.toString(),
      'price': price.toString(),
      'customer': customerController.text,
      'userId': currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      if (id != null && id.isNotEmpty) {
        await FirebaseService.updateRecord('sales', id, record);
        if (index != null) await LocalDBService.updateRecord('sales', index, record);
      } else {
        await FirebaseService.addRecord('sales', record);
        await LocalDBService.saveRecord('sales', record);
      }

      _clearControllers();
      Navigator.pop(context);
      _loadSales();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? '✅ Sale added!' : '✅ Sale updated!',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  // ---------------------------
  // DELETE SALE
  // ---------------------------
  Future<void> _deleteSale(Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        title: const Text('Delete Sale', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${record['item']}"?',
            style: const TextStyle(color: Colors.white70)),
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
        await FirebaseService.deleteRecord('sales', record['id']);
      }
      final index = sales.indexOf(record);
      await LocalDBService.deleteRecord('sales', index);
      _loadSales();
    } catch (e) {
      debugPrint('⚠ Error: $e');
    }
  }

  // ---------------------------
  // SALES DIALOG
  // ---------------------------
  void _showSaleDialog({Map<String, dynamic>? record, int? index}) {
    if (record != null) {
      itemController.text = record['item'];
      quantityController.text = record['quantity'];
      priceController.text = record['price'];
      customerController.text = record['customer'];
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
              children: [
                Text(record == null ? 'Add Sale' : 'Edit Sale',
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 18),

                // DROPDOWN for items
                DropdownButtonFormField<String>(
                  value: record != null ? record['item'] : null,
                  items: purchasedItems
                      .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(color: Colors.white)),
                  ))
                      .toList(),
                  dropdownColor: primary,
                  decoration: _inputDecoration("Item"),
                  onChanged: (value) => itemController.text = value ?? '',
                ),

                const SizedBox(height: 12),
                _buildField(quantityController, 'Quantity'),
                _buildField(priceController, 'Price'),
                _buildField(customerController, 'Customer'),

                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed: () => _saveSale(id: record?['id'], index: index, editingRecord: record),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text(record == null ? 'Save' : 'Update',
                      style: const TextStyle(color: primary)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2)),
    );
  }

  Widget _buildField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      keyboardType: label == 'Quantity' || label == 'Price' ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _saleCard(Map<String, dynamic> record, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.white),
        title: Text(record['item'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
            "Qty: ${record['quantity']} | Price: ${record['price']} | Customer: ${record['customer']}",
            style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteSale(record)),
        onTap: () => _showSaleDialog(record: record, index: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Sales", style: TextStyle(color: Colors.white)),
        actions: [
          Switch(
            value: useFirebase,
            onChanged: (v) {
              setState(() => useFirebase = v);
              _loadSales();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : sales.isEmpty
          ? const Center(
        child: Text("No sales records.", style: TextStyle(color: Colors.white70)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        itemBuilder: (_, i) => _saleCard(sales[i], i),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        onPressed: () => _showSaleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
