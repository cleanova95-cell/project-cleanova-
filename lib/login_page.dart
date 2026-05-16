import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_selection_page.dart';
import 'customer_dashboard.dart';
import 'cleaner_dashboard.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool isHidden = true;
  bool remember = false;

  TextEditingController emailController =
  TextEditingController();

  TextEditingController passwordController =
  TextEditingController();

  Future<void> loginUser() async {

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (!email.contains('@')) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (password.length < 6) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 6 characters",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {

      UserCredential userCredential =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User data not found"),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      String role = userDoc['role'];

      if (role == 'customer') {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Customer login success"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const CustomerDashboard(),
          ),
        );

      }

      else if (role == 'cleaner') {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cleaner login success"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const CleanerDashboard(),
          ),
        );

      }

      else if (role == 'admin') {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin login success"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const AdminDashboard(),
          ),
        );

      }

      else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid user role"),
            backgroundColor: Colors.red,
          ),
        );

      }

    } on FirebaseAuthException catch (e) {

      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = "Email not registered";
      }

      else if (e.code == 'wrong-password') {
        message = "Wrong password";
      }

      else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );

    }
  }

  Future<void> resetPassword() async {

    final email = emailController.text.trim();

    if (email.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email first"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {

      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message = "Error";

      if (e.code == 'user-not-found') {
        message = "Email not registered";
      }

      else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF1F8E9),

      body: SingleChildScrollView(
        child: Padding(

          padding: const EdgeInsets.only(top: 80),

          child: Center(
            child: Container(

              margin: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,

                boxShadow: [

                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),

                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )

                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [

                  Stack(
                    children: [

                      Container(
                        height: 200,

                        decoration: const BoxDecoration(

                          borderRadius:
                          BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),

                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF56AB2F),
                              Color(0xFFA8E063),
                            ],
                          ),
                        ),
                      ),

                      const Positioned.fill(
                        child: Column(

                          mainAxisAlignment:
                          MainAxisAlignment.center,

                          children: [

                            Icon(
                              Icons.cleaning_services,
                              color: Colors.white,
                              size: 55,
                            ),

                            SizedBox(height: 8),

                            Text(
                              "CLEANOVA",

                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 20,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Padding(

                    padding: const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      20,
                    ),

                    child: Column(
                      children: [

                        const Text(
                          "Welcome Back!",

                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: emailController,

                          decoration: InputDecoration(
                            hintText: "Email",
                            filled: true,

                            fillColor:
                            const Color(0xFFF2F2F2),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(30),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: passwordController,
                          obscureText: isHidden,

                          decoration: InputDecoration(
                            hintText: "Password",
                            filled: true,

                            fillColor:
                            const Color(0xFFF2F2F2),

                            suffixIcon: IconButton(

                              icon: Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),

                              onPressed: () {

                                setState(() {
                                  isHidden = !isHidden;
                                });
                              },
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(30),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(

                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                          children: [

                            Row(
                              children: [

                                Checkbox(
                                  value: remember,

                                  onChanged: (v) {

                                    setState(() {
                                      remember = v!;
                                    });
                                  },
                                ),

                                const Text(
                                  "Remember me",

                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),

                              ],
                            ),

                            GestureDetector(
                              onTap: resetPassword,

                              child: const Text(
                                "Forgot password?",

                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            )

                          ],
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: loginUser,

                          child: Container(
                            width: double.infinity,
                            height: 50,

                            decoration: BoxDecoration(

                              borderRadius:
                              BorderRadius.circular(30),

                              border: Border.all(
                                color: Colors.green,
                              ),
                            ),

                            child: const Center(
                              child: Text(
                                "Login",

                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(

                          mainAxisAlignment:
                          MainAxisAlignment.center,

                          children: [

                            const Text("New user? "),

                            GestureDetector(
                              onTap: () {

                                Navigator.push(
                                  context,

                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const RegisterSelectionPage(),
                                  ),
                                );
                              },

                              child: const Text(
                                "Register",

                                style: TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                            ),

                          ],
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}