import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterCleanerPage extends StatefulWidget {
  const RegisterCleanerPage({super.key});

  @override
  State<RegisterCleanerPage> createState() =>
      _RegisterCleanerPageState();
}

class _RegisterCleanerPageState
    extends State<RegisterCleanerPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{8,15}$')
        .hasMatch(phone);
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('cleaners')
          .doc(uid)
          .set({
        'full_name': name,
        'email': email,
        'phone': phone,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Account created for $name!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Register failed";

      if (e.code == 'email-already-in-use') {
        message = "Email already used";
      } else if (e.code == 'weak-password') {
        message = "Password too weak";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
      Icon(prefixIcon, color: const Color(0xFF56AB2F)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
            color: Color(0xFF56AB2F), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF56AB2F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                const Icon(
                    Icons.cleaning_services_outlined,
                    size: 64,
                    color: Color(0xFF56AB2F)),
                const SizedBox(height: 12),
                const Text(
                  'Join Cleanova',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fill in your details to become a cleaner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextField(
                  controller: _nameController,
                  textCapitalization:
                  TextCapitalization.words,
                  decoration: _fieldDecoration(
                    label: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  decoration: _fieldDecoration(
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Phone Number
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _fieldDecoration(
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() =>
                      _obscurePassword =
                      !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextField(
                  controller:
                  _confirmPasswordController,
                  obscureText:
                  _obscureConfirmPassword,
                  decoration: _fieldDecoration(
                    label: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() =>
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF56AB2F),
                          Color(0xFFA8E063)
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed:
                      _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.transparent,
                        shadowColor:
                        Colors.transparent,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Create Account',
                        style:
                        TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to login
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Text(
                        'Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.popUntil(
                          context,
                              (route) => route.isFirst),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF56AB2F),
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@pragma('flutter_widget_preview')
Widget previewRegisterPage() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RegisterCleanerPage(),
  );
}