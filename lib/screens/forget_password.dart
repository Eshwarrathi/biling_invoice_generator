import 'package:flutter/material.dart';
import '../services/Auth_servies.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final AuthServices authServices = AuthServices();
  bool isLoading = false;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  void resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗ Please enter your email"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Email validation
    if (!emailController.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗ Please enter a valid email address"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final done = await authServices.resetPassword(emailController.text.trim());

    setState(() => isLoading = false);

    if (done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📩 Reset link sent! Check your email."),
          backgroundColor: Color(0xFF00C2A8),
        ),
      );

      // Wait a bit then go back
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context); // ← back to login screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Failed to send reset link. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                  border: Border.all(color: accent, width: 2),
                ),
                child: Icon(Icons.lock_reset, size: 60, color: accent),
              ),
              const SizedBox(height: 30),

              Text(
                "Reset Password",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 15),

              Text(
                "Enter your registered email address and we'll send you a password reset link.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Enter your email",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.email, color: accent),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: accent))
                    : ElevatedButton(
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Send Reset Link",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Back to login button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Back to Login",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}