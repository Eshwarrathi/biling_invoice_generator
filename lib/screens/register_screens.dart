import 'package:flutter/material.dart';
import '../services/Auth_servies.dart';
import '../services/access_rules.dart';
import 'Home_screens.dart';
import 'login_screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthServices authServices = AuthServices();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmVisible = false;

  String selectedRole = 'user'; // default to user
  List<String> roles = AccessRules.availableRoles;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!AccessRules.availableRoles.contains(selectedRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid role selected'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => isLoading = true);

    final cred = await authServices.signUpWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
      role: selectedRole,
    );

    setState(() => isLoading = false);

    if (cred != null) {
      // ✅ Show email verification message with option to resend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Registration Successful!'),
              SizedBox(height: 5),
              Text('Please check your email to verify your account.', style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: accent,
          duration: Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Resend Email',
            textColor: Colors.white,
            onPressed: () {
              cred.user?.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📧 Verification email resent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      );

      // ✅ Go to login screen after delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Registration failed'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
        prefixIcon: const Icon(Icons.lock, color: accent),
        suffixIcon: IconButton(
          icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: accent.withOpacity(0.7)),
          onPressed: toggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withOpacity(0.25),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Icon(Icons.person_add_alt_1,
                      size: 50, color: accent),
                ),
                const SizedBox(height: 18),
                const Text('Recora',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('Create your account',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 35),

                _inputField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validator: (v) =>
                  v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 18),

                _passwordField(
                  controller: passwordController,
                  label: 'Password',
                  isVisible: isPasswordVisible,
                  toggleVisibility: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                  validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Min 6 chars',
                ),
                const SizedBox(height: 18),

                _passwordField(
                  controller: confirmController,
                  label: 'Confirm Password',
                  isVisible: isConfirmVisible,
                  toggleVisibility: () =>
                      setState(() => isConfirmVisible = !isConfirmVisible),
                  validator: (v) => v != null && v.isNotEmpty
                      ? null
                      : 'Confirm password',
                ),
                const SizedBox(height: 18),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      dropdownColor: primary,
                      icon: Icon(Icons.arrow_drop_down, color: accent),
                      decoration: InputDecoration(
                        labelText: 'Select Role',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.person_outline, color: accent),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: roles
                          .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase(),
                              style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => selectedRole = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: isLoading
                      ? const Center(
                      child: CircularProgressIndicator(color: accent))
                      : ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Register',
                        style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}