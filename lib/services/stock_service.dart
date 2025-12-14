import 'firestore_servicves.dart';
import 'local_db_service.dart';

class StockService {
  static Future<List<Map<String, dynamic>>> calculateStock({
    bool useFirebase = true,
    required String userId,
  }) async {
    try {
      List<Map<String, dynamic>> purchases = [];
      List<Map<String, dynamic>> sales = [];

      if (useFirebase) {
        // ✅ Firebase سے صرف current user کا ڈیٹا لوڈ کریں
        purchases = await FirebaseService.getAllRecords('purchases');
        sales = await FirebaseService.getAllRecords('sales');

        // Filter by user ID
        purchases = purchases.where((p) => p['userId'] == userId).toList();
        sales = sales.where((s) => s['userId'] == userId).toList();
      } else {
        // ✅ Hive سے ڈیٹا لوڈ کریں
        final purchasesBox = LocalDBService.getAllRecords('purchases');
        final salesBox = LocalDBService.getAllRecords('sales');

        purchases = purchasesBox
            .where((item) => item['userId'] == userId)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        sales = salesBox
            .where((item) => item['userId'] == userId)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      // Stock calculation logic
      Map<String, Map<String, int>> stockMap = {};

      // Add purchases
      for (var purchase in purchases) {
        final item = purchase['item']?.toString() ?? '';
        final quantity = int.tryParse(purchase['quantity']?.toString() ?? '0') ?? 0;

        if (!stockMap.containsKey(item)) {
          stockMap[item] = {'purchased': 0, 'sold': 0, 'remaining': 0};
        }
        stockMap[item]!['purchased'] = stockMap[item]!['purchased']! + quantity;
        stockMap[item]!['remaining'] = stockMap[item]!['remaining']! + quantity;
      }

      // Subtract sales
      for (var sale in sales) {
        final item = sale['item']?.toString() ?? '';
        final quantity = int.tryParse(sale['quantity']?.toString() ?? '0') ?? 0;

        if (stockMap.containsKey(item)) {
          stockMap[item]!['sold'] = stockMap[item]!['sold']! + quantity;
          stockMap[item]!['remaining'] = stockMap[item]!['remaining']! - quantity;
        } else {
          // If item sold but never purchased
          stockMap[item] = {'purchased': 0, 'sold': quantity, 'remaining': -quantity};
        }
      }

      // Convert to list
      List<Map<String, dynamic>> stockList = [];

      for (var entry in stockMap.entries) {
        final item = entry.key;
        final purchased = entry.value['purchased'] ?? 0;
        final sold = entry.value['sold'] ?? 0;
        final remaining = entry.value['remaining'] ?? 0;

        stockList.add({
          'item': item,
          'purchased': purchased,
          'sold': sold,
          'remaining': remaining,
        });
      }

      // Sort by item name
      stockList.sort((a, b) => (a['item'] ?? '').compareTo(b['item'] ?? ''));

      return stockList;
    } catch (e) {
      print('❌ Error calculating stock: $e');
      return [];
    }
  }

  // ✅ Additional method to get low stock items
  static Future<List<Map<String, dynamic>>> getLowStock({
    bool useFirebase = true,
    required String userId,
    int threshold = 5,
  }) async {
    final allStock = await calculateStock(useFirebase: useFirebase, userId: userId);
    return allStock.where((item) => (item['remaining'] ?? 0) <= threshold).toList();
  }

  // ✅ Method to check specific item stock
  static Future<int> getItemStock({
    bool useFirebase = true,
    required String userId,
    required String itemName,
  }) async {
    final allStock = await calculateStock(useFirebase: useFirebase, userId: userId);
    final item = allStock.firstWhere(
          (stock) => (stock['item'] ?? '').toLowerCase() == itemName.toLowerCase(),
      orElse: () => {'remaining': 0},
    );
    return item['remaining'] ?? 0;
  }
}