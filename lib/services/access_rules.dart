class AccessRules {
  static const Map<String, List<String>> roleScreens = {
    'admin': [
      'Purchase',
      'Sales',
      'Expenses',
      'HR Management',
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
    'user': [   // 👈 Updated user role
      'Purchase',
      'Sales',
      'Stock',
    ],
  };

  static bool hasAccess(String role, String screenName) {
    return roleScreens[role]?.contains(screenName) ?? false;
  }

  static List<String> get availableRoles => ['admin', 'cashier', 'manager', 'accountant', 'user'];
}
