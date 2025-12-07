import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';
class SalaryScreen extends StatefulWidget {
  final String currentUserId; // logged-in user ID
  final List<Map<String, dynamic>> employees;
  const SalaryScreen({super.key, required this.employees, required this.currentUserId});
  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}
class _SalaryScreenState extends State<SalaryScreen> {
  final Map<String, TextEditingController> extraPayControllers = {};
  final Map<String, TextEditingController> deductionControllers = {};

  static const Color primary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void dispose() {
    for (var c in extraPayControllers.values) c.dispose();
    for (var c in deductionControllers.values) c.dispose();
    super.dispose();
  }

  double _calculateTotal(double base, String extra, String deduction) {
    final extraVal = double.tryParse(extra) ?? 0;
    final dedVal = double.tryParse(deduction) ?? 0;
    return base + extraVal - dedVal;
  }

  Future<void> _saveAllSalaries() async {
    try {
      for (var emp in widget.employees) {
        // Only save salaries for employees belonging to the current user
        if (emp['userId'] != widget.currentUserId) continue;

        final empId = emp['employeeId'];
        final extra = double.tryParse(extraPayControllers[empId]?.text ?? '0') ?? 0;
        final deduction = double.tryParse(deductionControllers[empId]?.text ?? '0') ?? 0;
        final baseSalary = emp['salary'] is num
            ? emp['salary'].toDouble()
            : double.tryParse(emp['salary'].toString()) ?? 0.0;

        final total = _calculateTotal(baseSalary, extra.toString(), deduction.toString());

        final salaryRecord = {
          'userId': widget.currentUserId, // assign current user
          'employeeId': empId,
          'name': emp['name'],
          'position': emp['position'],
          'baseSalary': baseSalary,
          'extraPay': extra,
          'deduction': deduction,
          'totalPay': total,
          'month': DateTime.now().month,
          'year': DateTime.now().year,
          'createdAt': DateTime.now().toIso8601String(),
        };

        if (emp['id'] != null) {
          await FirebaseService.addRecord('salaries', salaryRecord);
        }
        await LocalDBService.saveRecord('salaries', salaryRecord);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ All salary records saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving salaries: $e')),
      );
    }
  }

  Widget _salaryCard(Map<String, dynamic> emp) {
    final empId = emp['employeeId'];
    extraPayControllers[empId] ??= TextEditingController();
    deductionControllers[empId] ??= TextEditingController();

    final baseSalary = emp['salary'] is num
        ? emp['salary'].toDouble()
        : double.tryParse(emp['salary'].toString()) ?? 0.0;

    final total = _calculateTotal(
      baseSalary,
      extraPayControllers[empId]!.text,
      deductionControllers[empId]!.text,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👤 ${emp['name'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          Text('💼 ${emp['position'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Base Salary: PKR $baseSalary', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildField(extraPayControllers[empId]!, 'Extra Payment', Icons.add)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(deductionControllers[empId]!, 'Deduction', Icons.remove)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Total Pay: PKR ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = widget.employees.where((e) => e['userId'] == widget.currentUserId).toList(); // filter by user

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('💰 Salary Calculation', style: TextStyle(color: Colors.white)),
      ),
      body: employees.isEmpty
          ? const Center(
        child: Text('No employees found for this user.',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: employees.length,
        itemBuilder: (_, i) => _salaryCard(employees[i]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: _saveAllSalaries,
          icon: const Icon(Icons.save),
          label: const Text('Save All Salaries', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
