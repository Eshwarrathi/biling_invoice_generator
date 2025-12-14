import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/stock_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool isLoading = true;
  bool useFirebase = true;
  List<Map<String, dynamic>> stock = [];

  // ✅ Dynamic current user ID
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  Future<void> loadStock() async {
    setState(() => isLoading = true);
    try {
      stock = await StockService.calculateStock(
        useFirebase: useFirebase,
        userId: currentUserId, // ✅ Current user ID استعمال کریں
      );
    } catch (e) {
      print('❌ Error loading stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
            s['item'] ?? 'Unknown Item',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Purchased: ${s['purchased'] ?? 0}", style: const TextStyle(color: Colors.white70)),
          Text("Sold: ${s['sold'] ?? 0}", style: const TextStyle(color: Colors.white70)),
          Text(
            "Remaining: ${s['remaining'] ?? 0}",
            style: TextStyle(
              color: (s['remaining'] ?? 0) <= 0 ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                activeThumbColor: Colors.white,
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
          ? const Center(
        child: Text(
          "No stock data available",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadStock,
        backgroundColor: primary,
        color: accent,
        child: ListView.builder(
          itemCount: stock.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => _stockCard(stock[i]),
        ),
      ),
    );
  }
}