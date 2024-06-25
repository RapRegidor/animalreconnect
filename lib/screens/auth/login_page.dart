// ignore_for_file: avoid_print

import 'package:animalreconnect/controller/user_controller.dart';
import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _isPasswordObscured = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
          child: Column(
            children: [
              //logo
              Image.asset('lib/images/animalReconnect_logo.png',
                  height: screenHeight * 0.3),

              //name
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                child: Text(
                  'Animal Reconnect',
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.13),
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      final user = await UserController.loginWithGoogle();
                      if (user != null && context.mounted) {
                        final userDoc = FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid);
                        final docSnapshot = await userDoc.get();

                        if (docSnapshot.exists && docSnapshot.data() != null) {
                          navigateTo('/verifyEmail/');
                        }
                      }
                    } on FirebaseAuthException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(error.message ?? "Something went wrong"),
                        ));
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error.toString()),
                        ));
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Image.asset('lib/images/google_logo.png',
                            height: screenHeight * 0.03),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Continue with Google',
                          style: GoogleFonts.inriaSans(
                            fontSize: screenHeight * 0.02,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //or
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, screenHeight * 0.02, 0, screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.35,
                      height: 1,
                      color: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or',
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.017,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.35,
                      height: 1,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(children: [
                  //username/address text field
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.12,
                        screenHeight * 0.017,
                        screenWidth * 0.12,
                        screenHeight * 0.017),
                    child: TextField(
                      controller: _email,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.fromLTRB(
                              10, screenHeight * 0.02, 10, screenHeight * 0.02),
                          hintText: 'Email address'),
                    ),
                  ),
                  //password text field

                  Padding(
                    padding: EdgeInsets.fromLTRB(screenWidth * 0.12,
                        screenHeight * 0.017, screenWidth * 0.12, 0),
                    child: TextField(
                      controller: _password,
                      obscureText: _isPasswordObscured,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(
                            10, screenHeight * 0.02, 10, screenHeight * 0.02),
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            size: screenHeight * 0.025,
                            _isPasswordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                  ),

                  //forgot password
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.1, 0, 0, 0), // Adjust left padding
                    child: Align(
                      alignment:
                          Alignment.centerLeft, // Aligns text to the left
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/resetPassword/', (_) => false);
                        },
                        child: Text(
                          'Forgot your password?',
                          style: GoogleFonts.inriaSans(
                            fontSize: screenHeight * 0.017,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),

                  //login button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                    child: createButton(
                        screenWidth * 0.8,
                        screenHeight * 0.06,
                        () => handleLogin(),
                        'LOG IN',
                        Colors.white,
                        screenHeight * 0.0225,
                        const Color.fromARGB(255, 247, 184, 1),
                        const Color.fromARGB(255, 241, 132, 1),
                        Colors.transparent,
                        Colors.transparent),
                  ),
                ]),
              ),

              //divider

              Container(
                width: screenWidth * 0.9,
                height: 1,
                color: Colors.grey,
              ),

              //not a member | create account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member? |',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.016,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/register/', (_) => false);
                    },
                    child: Text(
                      'Create an account',
                      style: GoogleFonts.inriaSans(
                        fontSize: screenHeight * 0.016,
                        color: const Color.fromARGB(255, 255, 60, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }

  void handleLogin() async {
    final email = _email.text;
    final password = _password.text;
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        navigateTo('/verifyEmail/');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email Not Found')),
          );
          return;
        }
      } else if (e.code == 'wrong-password') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong Password')),
          );
          return;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Something Wrong Happened! ${e.code}')),
          );
          return;
        }
      }
    }
  }

  void navigateTo(String route) {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    }
  }
}
