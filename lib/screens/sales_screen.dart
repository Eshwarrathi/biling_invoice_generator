import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_services.dart';
import '../services/local_db_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Text controllers
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  // State variables
  List<Map<String, dynamic>> _sales = [];
  List<String> _purchasedItems = [];
  bool _useFirebase = true;
  bool _isLoading = false;
  String? _selectedItem;

  // Colors
  static const Color _primaryColor = Color(0xFF0B1B3A);
  static const Color _accentColor = Color(0xFF00C2A8);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF4CAF50);

  // Get current user ID
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================
  Future<void> _initializeData() async {
    await Future.wait([
      _loadPurchasedItems(),
      _loadSales(),
    ]);
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadPurchasedItems() async {
    try {
      final purchaseRecords = await FirebaseService.getAllRecords('purchases');
      if (mounted) {
        setState(() {
          _purchasedItems = purchaseRecords
              .where((r) => r['userId'] == _currentUserId)
              .map<String>((r) => r['item'].toString())
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load purchased items: ${e.toString()}');
    }
  }

  Future<void> _loadSales() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      List<Map<String, dynamic>> data = [];

      if (_useFirebase) {
        final allRecords = await FirebaseService.getAllRecords('sales');
        data = allRecords.where((r) => r['userId'] == _currentUserId).toList();
      } else {
        final localRecords = LocalDBService.getAllRecords('sales');
        data = localRecords
            .map((e) => Map<String, dynamic>.from(e))
            .where((r) => r['userId'] == _currentUserId)
            .toList();
      }

      if (mounted) {
        setState(() => _sales = data);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load sales: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== STOCK MANAGEMENT ====================
  Future<int> _getAvailableStock(String item, {Map<String, dynamic>? editingRecord}) async {
    try {
      int totalPurchased = 0;
      int totalSold = 0;

      // Calculate total purchased
      final purchaseRecords = await FirebaseService.getAllRecords('purchases');
      for (var record in purchaseRecords) {
        if (record['userId'] == _currentUserId && record['item'] == item) {
          totalPurchased += int.tryParse(record['quantity'].toString()) ?? 0;
        }
      }

      // Calculate total sold
      final salesRecords = await FirebaseService.getAllRecords('sales');
      for (var record in salesRecords) {
        if (record['userId'] == _currentUserId && record['item'] == item) {
          // If editing, subtract the original quantity first
          if (editingRecord != null &&
              record['id'] == editingRecord['id']) {
            continue;
          }
          totalSold += int.tryParse(record['quantity'].toString()) ?? 0;
        }
      }

      return totalPurchased - totalSold;
    } catch (e) {
      debugPrint('Error calculating stock: $e');
      return 0;
    }
  }

  // ==================== SALE OPERATIONS ====================
  Future<void> _saveSale({
    String? id,
    int? index,
    Map<String, dynamic>? editingRecord,
  }) async {
    // Validate inputs
    if (!_validateInputs(editingRecord)) return;

    final quantity = int.parse(_quantityController.text);
    final price = double.parse(_priceController.text);
    final item = _selectedItem ?? _itemController.text;

    // Validate stock
    try {
      final availableStock = await _getAvailableStock(
        item,
        editingRecord: editingRecord,
      );

      if (quantity > availableStock) {
        _showErrorSnackBar(
          'Not enough stock!\nAvailable: $availableStock\nRequested: $quantity',
        );
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Error checking stock: ${e.toString()}');
      return;
    }

    // Prepare record
    final record = {
      'item': item,
      'quantity': quantity.toString(),
      'price': price.toStringAsFixed(2),
      'customer': _customerController.text.trim(),
      'userId': _currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Save record
    try {
      if (id != null && id.isNotEmpty) {
        await FirebaseService.updateRecord('sales', id, record);
        if (index != null) {
          await LocalDBService.updateRecord('sales', index, record);
        }
      } else {
        await FirebaseService.addRecord('sales', record);
        await LocalDBService.saveRecord('sales', record);
      }

      // Refresh and show success
      _clearControllers();
      Navigator.pop(context);
      await _loadSales();

      _showSuccessSnackBar(
        id == null ? 'Sale added successfully!' : 'Sale updated successfully!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save sale: ${e.toString()}');
    }
  }

  Future<void> _deleteSale(Map<String, dynamic> record) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Sale',
      message: 'Are you sure you want to delete sale of "${record['item']}"?',
      confirmText: 'Delete',
      confirmColor: _errorColor,
    );

    if (!confirmed) return;

    try {
      if (record['id'] != null) {
        await FirebaseService.deleteRecord('sales', record['id']);
      }

      final index = _sales.indexWhere((s) => s['id'] == record['id']);
      if (index != -1) {
        await LocalDBService.deleteRecord('sales', index);
      }

      await _loadSales();
      _showSuccessSnackBar('Sale deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to delete sale: ${e.toString()}');
    }
  }

  // ==================== VALIDATION ====================
  bool _validateInputs(Map<String, dynamic>? editingRecord) {
    final item = _selectedItem ?? _itemController.text.trim();
    final quantity = _quantityController.text.trim();
    final price = _priceController.text.trim();
    final customer = _customerController.text.trim();

    // Check if item exists in purchased items
    if (!_purchasedItems.contains(item)) {
      _showErrorSnackBar('This item is not available in purchases!');
      return false;
    }

    // Check required fields
    if (item.isEmpty || quantity.isEmpty || price.isEmpty || customer.isEmpty) {
      _showErrorSnackBar('Please fill all required fields!');
      return false;
    }

    // Validate quantity
    final quantityInt = int.tryParse(quantity);
    if (quantityInt == null || quantityInt <= 0) {
      _showErrorSnackBar('Quantity must be a positive number!');
      return false;
    }

    // Validate price
    final priceDouble = double.tryParse(price);
    if (priceDouble == null || priceDouble <= 0) {
      _showErrorSnackBar('Price must be a positive number!');
      return false;
    }

    return true;
  }

  // ==================== UI HELPERS ====================
  void _showSaleDialog({Map<String, dynamic>? record, int? index}) {
    if (record != null) {
      _selectedItem = record['item'];
      _itemController.text = record['item'];
      _quantityController.text = record['quantity'];
      _priceController.text = record['price'];
      _customerController.text = record['customer'];
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _accentColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record == null ? 'Add New Sale' : 'Edit Sale',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Item Dropdown
                _buildItemDropdown(record),

                const SizedBox(height: 16),

                // Quantity Field
                _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  keyboardType: TextInputType.number,
                  icon: Icons.numbers,
                ),

                const SizedBox(height: 16),

                // Price Field
                _buildTextField(
                  controller: _priceController,
                  label: 'Price',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.attach_money,
                ),

                const SizedBox(height: 16),

                // Customer Field
                _buildTextField(
                  controller: _customerController,
                  label: 'Customer',
                  keyboardType: TextInputType.text,
                  icon: Icons.person,
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearControllers();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveSale(
                          id: record?['id'],
                          index: index,
                          editingRecord: record,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          record == null ? 'Save' : 'Update',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildItemDropdown(Map<String, dynamic>? record) {
    return DropdownButtonFormField<String>(
      value: _selectedItem,
      items: _purchasedItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedItem = value;
          _itemController.text = value ?? '';
        });
      },
      decoration: _inputDecoration(
        label: 'Item *',
        icon: Icons.inventory,
      ),
      dropdownColor: _primaryColor,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      style: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(12),
      hint: const Text(
        'Select an item',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> record, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _primaryColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _accentColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: _accentColor.withOpacity(0.2),
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          record['item']?.toString() ?? 'Unknown Item',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Qty: ${record['quantity']} | Price: ${record['price']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              'Customer: ${record['customer']}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: _primaryColor,
          onSelected: (value) {
            if (value == 'edit') {
              _showSaleDialog(record: record, index: index);
            } else if (value == 'delete') {
              _deleteSale(record);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showSaleDialog(record: record, index: index),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================
  void _clearControllers() {
    _itemController.clear();
    _quantityController.clear();
    _priceController.clear();
    _customerController.clear();
    setState(() => _selectedItem = null);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _primaryColor,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _accentColor.withOpacity(0.3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          "Sales",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text(
                  'Online',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _useFirebase,
                  onChanged: (value) {
                    setState(() => _useFirebase = value);
                    _loadSales();
                  },
                  activeColor: _accentColor,
                  activeTrackColor: _accentColor.withOpacity(0.3),
                ),
                const Text(
                  'Local',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: _accentColor,
          strokeWidth: 2,
        ),
      )
          : _sales.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              "No sales records found",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _useFirebase ? 'Cloud storage' : 'Local storage',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: _accentColor,
        backgroundColor: _primaryColor,
        onRefresh: _loadSales,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _sales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _buildSaleCard(
            _sales[index],
            index,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _purchasedItems.isEmpty
            ? () {
          _showErrorSnackBar('No purchased items available!');
        }
            : () => _showSaleDialog(),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
    );
  }
}