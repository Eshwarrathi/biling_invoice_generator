import 'package:flutter/material.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';
import 'salary_screen.dart';

class HRScreen extends StatefulWidget {
  final String currentUserId; // logged-in user ID
  const HRScreen({super.key, required this.currentUserId});

  @override
  State<HRScreen> createState() => _HRScreenState();
}

class _HRScreenState extends State<HRScreen> {
  List<Map<String, dynamic>> employees = [];
  bool useFirebase = true;
  bool isLoading = false;

  static const Color primary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];
      if (useFirebase) {
        data = await FirebaseService.getAllRecords('employees');
      } else {
        final local = LocalDBService.getAllRecords('employees');
        data = local.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Filter employees by current user
      data = data.where((e) => e['userId'] == widget.currentUserId).toList();

      setState(() => employees = data);
    } catch (e) {
      debugPrint('⚠️ Error loading employees: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showEmployeeDialog({Map<String, dynamic>? record, int? index}) {
    final employeeIdController = TextEditingController(text: record?['employeeId'] ?? DateTime.now().millisecondsSinceEpoch.toString());
    final nameController = TextEditingController(text: record?['name'] ?? '');
    final phoneController = TextEditingController(text: record?['phone'] ?? '');
    final positionController = TextEditingController(text: record?['position'] ?? '');
    final salaryController = TextEditingController(text: record?['salary']?.toString() ?? '');
    final dobController = TextEditingController(text: record?['dob'] ?? '');
    final joiningController = TextEditingController(text: record?['joiningDate'] ?? '');

    final isEditing = record != null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? '✏️ Edit Employee' : '👨‍💼 Add Employee',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                _buildField(employeeIdController, 'Employee ID'),
                _buildField(nameController, 'Name'),
                _buildField(phoneController, 'Phone', isNumber: true),
                _buildField(positionController, 'Position'),
                _buildField(salaryController, 'Salary', isNumber: true),
                _buildField(dobController, 'Date of Birth', isDate: true),
                _buildField(joiningController, 'Joining Date', isDate: true),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || salaryController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Name and Salary are required', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final recordData = {
                      'userId': widget.currentUserId, // attach current user
                      'employeeId': employeeIdController.text.trim(),
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'position': positionController.text.trim(),
                      'salary': double.tryParse(salaryController.text) ?? 0.0,
                      'dob': dobController.text.trim(),
                      'joiningDate': joiningController.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    };

                    try {
                      if (isEditing && record?['id'] != null) {
                        if (useFirebase) await FirebaseService.updateRecord('employees', record!['id'], recordData);
                        if (index != null) await LocalDBService.updateRecord('employees', index, recordData);
                      } else {
                        if (useFirebase) await FirebaseService.addRecord('employees', recordData);
                        await LocalDBService.saveRecord('employees', recordData);
                      }

                      Navigator.pop(context);
                      _loadEmployees();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? '✅ Employee updated' : '✅ Employee added',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: accent,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e', style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, {bool isNumber = false, bool isDate = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        readOnly: isDate,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white30)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
        ),
        onTap: isDate
            ? () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (picked != null) c.text = picked.toIso8601String().split('T').first;
        }
            : null,
      ),
    );
  }

  Future<void> _deleteEmployee(Map<String, dynamic> record, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${record['name']}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (useFirebase && record['id'] != null) await FirebaseService.deleteRecord('employees', record['id']);
      await LocalDBService.deleteRecord('employees', index);
      _loadEmployees();
    } catch (e) {
      debugPrint('⚠️ Error deleting employee: $e');
    }
  }

  Widget _employeeCard(Map<String, dynamic> record, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        title: Text('${record['employeeId'] ?? '-'} | ${record['name'] ?? 'Unnamed'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '📞 ${record['phone'] ?? '-'}\n🎂 DOB: ${record['dob'] ?? '-'}\n📅 Joined: ${record['joiningDate'] ?? '-'}\n💼 ${record['position'] ?? '-'}\n💰 Salary: PKR ${record['salary'] ?? 0}',
          style: const TextStyle(color: Colors.white70),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showEmployeeDialog(record: record, index: index)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteEmployee(record, index)),
          ],
        ),
        onTap: () => _showEmployeeDialog(record: record, index: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('👨‍💼 HR Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SalaryScreen(employees: employees, currentUserId: '',)));
            },
          ),
          Row(
            children: [
              const Text("💾", style: TextStyle(color: Colors.white)),
              Switch(value: useFirebase, onChanged: (v) { setState(() => useFirebase = v); _loadEmployees(); }, activeColor: Colors.white),
              const Text("☁️", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : employees.isEmpty
          ? const Center(child: Text("No employees added.", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: employees.length, itemBuilder: (_, i) => _employeeCard(employees[i], i)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Employee", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showEmployeeDialog(),
      ),
    );
  }
}
