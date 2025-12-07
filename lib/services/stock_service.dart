import 'firestore_servicves.dart';
import 'local_db_service.dart';

class StockService {
  // Added optional parameters
  static Future<List<Map<String, dynamic>>> calculateStock({bool useFirebase = true, String? userId}) async {
    // Fetch purchase records
    final purchases = useFirebase
        ? await FirebaseService.getAllRecords('purchases')
        : LocalDBService.getAllRecords('purchases').map((e) => Map<String, dynamic>.from(e)).toList();

    // Fetch sales records
    final sales = useFirebase
        ? await FirebaseService.getAllRecords('sales')
        : LocalDBService.getAllRecords('sales').map((e) => Map<String, dynamic>.from(e)).toList();

    // Filter by current user if userId provided
    final filteredPurchases = userId == null ? purchases : purchases.where((p) => p['userId'] == userId).toList();
    final filteredSales = userId == null ? sales : sales.where((s) => s['userId'] == userId).toList();

    Map<String, int> purchaseMap = {};
    Map<String, int> saleMap = {};

    for (var p in filteredPurchases) {
      final item = p['item'];
      final qty = int.tryParse(p['quantity'] ?? '0') ?? 0;
      purchaseMap[item] = (purchaseMap[item] ?? 0) + qty;
    }

    for (var s in filteredSales) {
      final item = s['item'];
      final qty = int.tryParse(s['quantity'] ?? '0') ?? 0;
      saleMap[item] = (saleMap[item] ?? 0) + qty;
    }

    List<Map<String, dynamic>> stockList = [];

    for (var item in purchaseMap.keys) {
      final purchased = purchaseMap[item] ?? 0;
      final sold = saleMap[item] ?? 0;
      final remaining = purchased - sold;

      stockList.add({
        'item': item,
        'purchased': purchased,
        'sold': sold,
        'remaining': remaining,
      });
    }

    return stockList;
  }
}
