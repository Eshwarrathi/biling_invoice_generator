import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Auth_servies.dart';
import 'register_screens.dart';
import 'home_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthServices authServices = AuthServices();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  static const Color primary = Color(0xFF0B1B3A);
  static const Color accent = Color(0xFF00C2A8);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final cred = await authServices.signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (cred?.user != null) {
        // ✅ Check if email is verified (optional - you can enable/disable)
        if (!cred!.user!.emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Email not verified'),
                  SizedBox(height: 5),
                  Text('Please check your email for verification link.', style: TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Resend',
                onPressed: () {
                  cred.user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📧 Verification email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
          setState(() => isLoading = false);
          return;
        }

        final role = await authServices.getCurrentUserRole() ?? 'user';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Login Successful! Welcome $role'),
            backgroundColor: accent,
          ),
        );

        // ✅ Use named route for navigation
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'role': role},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Login Failed! Check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login Failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Account has been disabled';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Check your connection';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Login Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
                const SizedBox(height: 50),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.15),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: Icon(Icons.login, size: 50, color: accent),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recora',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Login to your account',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
                    prefixIcon: Icon(Icons.email, color: accent),
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
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
                    prefixIcon: Icon(Icons.lock, color: accent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: accent.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
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
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: accent))
                      : ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

// Forgot Password button پر
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold),
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
}