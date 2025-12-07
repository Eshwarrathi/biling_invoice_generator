import 'package:flutter/material.dart';
import '../services/stock_service.dart';
const String currentUserId = 'USER_123';
class StockScreen extends StatefulWidget {
  final bool initialUseFirebase;
  const StockScreen({super.key, this.initialUseFirebase = true});
  @override
  State<StockScreen> createState() => _StockScreenState();
}
class _StockScreenState extends State<StockScreen> {
  bool isLoading = true;
  bool useFirebase = true; // mutable in state
  List<Map<String, dynamic>> stock = [];
  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);
  @override
  void initState() {
    super.initState();
    useFirebase = widget.initialUseFirebase; // initialize from widget
    loadStock();
  }
  Future<void> loadStock() async {
    setState(() => isLoading = true);
    stock = await StockService.calculateStock(
      useFirebase: useFirebase,
      userId: currentUserId, // pass current user ID
    );
    setState(() => isLoading = false);
  }
  Widget _stockCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s['item'],
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Purchased: ${s['purchased']}", style: const TextStyle(color: Colors.white70)),
          Text("Sold: ${s['sold']}", style: const TextStyle(color: Colors.white70)),
          Text(
            "Remaining: ${s['remaining']}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        title: const Text("📦 Stock Summary", style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(
                value: useFirebase,
                onChanged: (v) {
                  setState(() => useFirebase = v);
                  loadStock();
                },
                activeColor: Colors.white,
              ),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : stock.isEmpty
          ? const Center(child: Text("No stock data", style: TextStyle(color: Colors.white70)))
          : RefreshIndicator(
        onRefresh: loadStock,
        child: ListView.builder(
          itemCount: stock.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => _stockCard(stock[i]),
        ),
      ),
    );
  }
}
