import 'package:flutter/material.dart';
import '../services/firestore_services.dart';
import '../services/local_db_service.dart';
import 'salary_screen.dart';

class HRScreen extends StatefulWidget {
  final String currentUserId;
  const HRScreen({super.key, required this.currentUserId});

  @override
  State<HRScreen> createState() => _HRScreenState();
}

class _HRScreenState extends State<HRScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _useFirebase = true;
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF0D47A1);
  static const Color _accentColor = Color(0xFF00C2A8);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadEmployees() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      List<Map<String, dynamic>> data = [];

      if (_useFirebase) {
        data = await FirebaseService.getAllRecords('employees');
      } else {
        final localRecords = LocalDBService.getAllRecords('employees');
        data = localRecords.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Filter by current user
      data = data.where((e) => e['userId'] == widget.currentUserId).toList();

      // Sort by name
      data.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      if (mounted) {
        setState(() => _employees = data);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load employees: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== EMPLOYEE OPERATIONS ====================
  Future<void> _saveEmployee({
    String? id,
    int? index,
    Map<String, dynamic>? record,
  }) async {
    // Get controllers from the dialog context
    final nameController = TextEditingController(text: record?['name'] ?? '');
    final phoneController = TextEditingController(text: record?['phone'] ?? '');
    final positionController = TextEditingController(text: record?['position'] ?? '');
    final salaryController = TextEditingController(text: record?['salary']?.toString() ?? '');
    final dobController = TextEditingController(text: record?['dob'] ?? '');
    final joiningController = TextEditingController(text: record?['joiningDate'] ?? '');
    final employeeIdController = TextEditingController(
      text: record?['employeeId'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(7),
    );

    // Validate inputs
    if (nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Employee name is required!');
      return;
    }

    if (salaryController.text.trim().isEmpty) {
      _showErrorSnackBar('Salary is required!');
      return;
    }

    final salary = double.tryParse(salaryController.text);
    if (salary == null || salary <= 0) {
      _showErrorSnackBar('Please enter a valid salary amount!');
      return;
    }

    // Prepare record
    final recordData = {
      'userId': widget.currentUserId,
      'employeeId': employeeIdController.text.trim(),
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'position': positionController.text.trim(),
      'salary': salary,
      'dob': dobController.text.trim(),
      'joiningDate': joiningController.text.trim(),
      'createdAt': record?['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (id != null && id.isNotEmpty) {
        // Update existing record
        if (_useFirebase) {
          await FirebaseService.updateRecord('employees', id, recordData);
        }
        if (index != null) {
          await LocalDBService.updateRecord('employees', index, recordData);
        }
      } else {
        // Add new record
        if (_useFirebase) {
          await FirebaseService.addRecord('employees', recordData);
        }
        await LocalDBService.saveRecord('employees', recordData);
      }

      Navigator.pop(context);
      await _loadEmployees();

      _showSuccessSnackBar(
        id == null ? 'Employee added successfully!' : 'Employee updated successfully!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save employee: ${e.toString()}');
    }
  }

  Future<void> _deleteEmployee(Map<String, dynamic> record, int index) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Employee',
      message: 'Are you sure you want to delete "${record['name']}"?',
      confirmText: 'Delete',
      confirmColor: _errorColor,
    );

    if (!confirmed) return;

    try {
      if (_useFirebase && record['id'] != null) {
        await FirebaseService.deleteRecord('employees', record['id']);
      }
      await LocalDBService.deleteRecord('employees', index);
      await _loadEmployees();
      _showSuccessSnackBar('Employee deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to delete employee: ${e.toString()}');
    }
  }

  // ==================== DIALOGS ====================
  void _showEmployeeDialog({Map<String, dynamic>? record, int? index}) {
    final isEditing = record != null;

    // Create controllers with existing data if editing
    final employeeIdController = TextEditingController(
      text: record?['employeeId'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(7),
    );
    final nameController = TextEditingController(text: record?['name'] ?? '');
    final phoneController = TextEditingController(text: record?['phone'] ?? '');
    final positionController = TextEditingController(text: record?['position'] ?? '');
    final salaryController = TextEditingController(text: record?['salary']?.toString() ?? '');
    final dobController = TextEditingController(text: record?['dob'] ?? '');
    final joiningController = TextEditingController(text: record?['joiningDate'] ?? '');

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
                  isEditing ? '✏️ Edit Employee' : '👨‍💼 Add Employee',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Employee ID (read-only for editing)
                _buildTextField(
                  controller: employeeIdController,
                  label: 'Employee ID',
                  icon: Icons.badge,
                  readOnly: isEditing,
                ),

                const SizedBox(height: 12),

                // Name Field
                _buildTextField(
                  controller: nameController,
                  label: 'Full Name *',
                  icon: Icons.person,
                ),

                const SizedBox(height: 12),

                // Phone Field
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                // Position Field
                _buildTextField(
                  controller: positionController,
                  label: 'Position',
                  icon: Icons.work,
                ),

                const SizedBox(height: 12),

                // Salary Field
                _buildTextField(
                  controller: salaryController,
                  label: 'Monthly Salary *',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 12),

                // Date of Birth Field
                _buildDateField(
                  controller: dobController,
                  label: 'Date of Birth',
                  icon: Icons.cake,
                ),

                const SizedBox(height: 12),

                // Joining Date Field
                _buildDateField(
                  controller: joiningController,
                  label: 'Joining Date',
                  icon: Icons.date_range,
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        onPressed: () => _saveEmployee(
                          id: record?['id'],
                          index: index,
                          record: record,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Update' : 'Save',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white70),
          onPressed: () => _selectDate(context, controller),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onTap: () => _selectDate(context, controller),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: _primaryColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _primaryColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // ==================== UI COMPONENTS ====================
  Widget _buildEmployeeCard(Map<String, dynamic> record, int index) {
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
          vertical: 16,
        ),
        leading: CircleAvatar(
          backgroundColor: _accentColor.withOpacity(0.2),
          child: Text(
            record['name']?.toString().substring(0, 1).toUpperCase() ?? 'E',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          record['name']?.toString() ?? 'Unnamed Employee',
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
              'ID: ${record['employeeId']} | ${record['position'] ?? 'No Position'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              '📞 ${record['phone'] ?? 'No Phone'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              '💰 PKR ${record['salary']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '📅 Joined: ${record['joiningDate'] ?? 'Not specified'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: _primaryColor,
          onSelected: (value) {
            if (value == 'edit') {
              _showEmployeeDialog(record: record, index: index);
            } else if (value == 'delete') {
              _deleteEmployee(record, index);
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
        onTap: () => _showEmployeeDialog(record: record, index: index),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================
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
          '👨‍💼 HR Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Fixed Salary Button
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SalaryScreen(
                    useFirebase: _useFirebase,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
            tooltip: 'Salary Calculation',
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              const Text(
                "💾",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _useFirebase,
                onChanged: (value) {
                  setState(() => _useFirebase = value);
                  _loadEmployees();
                },
                activeColor: Colors.white,
                activeTrackColor: _accentColor,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              const Text(
                "☁️",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : _employees.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white.withOpacity(0.3),
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              "No employees found",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
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
        onRefresh: _loadEmployees,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _employees.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _buildEmployeeCard(
            _employees[index],
            index,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeDialog(),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
    );
  }
}