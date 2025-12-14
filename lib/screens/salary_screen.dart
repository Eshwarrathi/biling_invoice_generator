import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

class SalaryScreen extends StatefulWidget {
  final bool useFirebase;
  const SalaryScreen({super.key, this.useFirebase = true});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final Map<String, TextEditingController> extraPayControllers = {};
  final Map<String, TextEditingController> deductionControllers = {};

  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const Color primary = Color(0xFF0B1B3A); // Changed to match app theme
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    for (var c in extraPayControllers.values) {
      c.dispose();
    }
    for (var c in deductionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => isLoading = true);
    try {
      if (widget.useFirebase) {
        final allEmployees = await FirebaseService.getAllRecords('employees');
        employees = allEmployees.where((e) => e['userId'] == currentUserId).toList();
      } else {
        final localEmployees = LocalDBService.getAllRecords('employees');
        employees = localEmployees
            .where((e) => e['userId'] == currentUserId)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      print('❌ Error loading employees: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  double _calculateTotal(double base, String extra, String deduction) {
    final extraVal = double.tryParse(extra) ?? 0;
    final dedVal = double.tryParse(deduction) ?? 0;
    return base + extraVal - dedVal;
  }

  Future<void> _saveAllSalaries() async {
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees to save salaries for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      int savedCount = 0;

      for (var emp in employees) {
        final empId = emp['employeeId'];
        final extra = double.tryParse(extraPayControllers[empId]?.text ?? '0') ?? 0;
        final deduction = double.tryParse(deductionControllers[empId]?.text ?? '0') ?? 0;
        final baseSalary = emp['salary'] is num
            ? emp['salary'].toDouble()
            : double.tryParse(emp['salary'].toString()) ?? 0.0;

        final total = _calculateTotal(baseSalary, extra.toString(), deduction.toString());

        final salaryRecord = {
          'userId': currentUserId,
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

        if (widget.useFirebase) {
          await FirebaseService.addRecord('salaries', salaryRecord);
        }
        await LocalDBService.saveRecord('salaries', salaryRecord);
        savedCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $savedCount salary records saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the controllers after saving
      for (var controller in extraPayControllers.values) {
        controller.clear();
      }
      for (var controller in deductionControllers.values) {
        controller.clear();
      }

      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving salaries: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _salaryCard(Map<String, dynamic> emp) {
    final empId = emp['employeeId']?.toString() ?? 'unknown';
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [primary, accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4)
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👤 ${emp['name'] ?? 'Unknown'}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white
                ),
              ),
              Text(
                'ID: ${emp['employeeId'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Text(
              '💼 ${emp['position'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70)
          ),
          const SizedBox(height: 12),
          Text(
              'Base Salary: Rs ${baseSalary.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16)
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildField(
                    extraPayControllers[empId]!,
                    'Extra Payment',
                    Icons.add_circle_outline
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                    deductionControllers[empId]!,
                    'Deduction',
                    Icons.remove_circle_outline
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    'Total Pay:',
                    style: TextStyle(color: Colors.white, fontSize: 16)
                ),
                Text(
                  'Rs ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: total >= baseSalary ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white30)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent)
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('💰 Salary Calculation', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEmployees,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : employees.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            const Text(
              'No employees found',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add employees in HR Management first',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to home
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to HR Management'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: primary,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: employees.length,
              itemBuilder: (_, i) => _salaryCard(employees[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: employees.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.all(12),
        color: primary,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveAllSalaries,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save All Salaries',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}