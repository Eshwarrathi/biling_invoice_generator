class AccessRules {
  static const Map<String, List<String>> roleScreens = {
    'admin': [
      'Purchase',
      'Sales',
      'Expenses',
      'HR Management',
      'Salary',
      'Payments',
      'Credit / Debit',
      'Calculation',
      'PDF Export',
      'Dashboard',
      'Stock',
    ],
    'cashier': [
      'Sales',
      'Payments',
      'PDF Export',
    ],
    'manager': [
      'Sales',
      'Purchase',
      'Stock',
      'HR Management',
      'Salary',
      'Payments',
      'Dashboard',
    ],
    'accountant': [
      'Expenses',
      'Payments',
      'Credit / Debit',
      'Calculation',
      'PDF Export',
      'Dashboard',
    ],
    'user': [
      'Purchase',
      'Sales',
      'Stock',
      'Salary',
    ],
  };

  static bool hasAccess(String role, String screenName) {
    // Check if role exists and if screen is in the role's list
    if (roleScreens.containsKey(role)) {
      return roleScreens[role]!.contains(screenName);
    }
    return false;
  }

  static List<String> get availableRoles => ['admin', 'cashier', 'manager', 'accountant', 'user'];

  // Additional helper methods
  static List<String> getScreensForRole(String role) {
    return roleScreens[role] ?? [];
  }

  static bool canEdit(String role) {
    // Define which roles have edit permissions
    return ['admin', 'manager'].contains(role);
  }

  static bool canDelete(String role) {
    // Define which roles have delete permissions
    return ['admin', 'manager'].contains(role);
  }

  static bool canViewAll(String role) {
    // Define which roles can view all records
    return ['admin', 'manager', 'accountant'].contains(role);
  }

  static Map<String, String> getRoleDescriptions() {
    return {
      'admin': 'Full access to all features and data',
      'cashier': 'Can process sales and payments only',
      'manager': 'Can manage purchases, sales, HR, and view reports',
      'accountant': 'Can manage finances, expenses, and generate reports',
      'user': 'Basic access to purchase, sales, stock, and salary features',
    };
  }
}