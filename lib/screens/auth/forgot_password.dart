import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final formkey = GlobalKey<FormState>();
  late final TextEditingController _email;

  @override
  void initState() {
    _email = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Reset Password'),
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(8.0, screenHeight * 0.1, 8.0, 8.0),
          child: Form(
            key: formkey,
            child: Center(
              child: Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Receive an email to\nreset your password',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inriaSans(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: TextFormField(
                        controller: _email,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Email'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (email) =>
                            email != null && !EmailValidator.validate(email)
                                ? 'Enter a valid email'
                                : null,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.075,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            gradient: const LinearGradient(colors: [
                              Color.fromARGB(255, 247, 184, 1),
                              Color.fromARGB(255, 241, 132, 1)
                            ])),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          onPressed: () async {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: _email.text.trim());
                            try {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Password Reset Email Sent')),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Reset Password',
                            style: GoogleFonts.inriaSans(
                              fontSize: screenHeight * 0.0225,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.075,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          onPressed: () => Navigator.of(context)
                              .pushNamedAndRemoveUntil('/login/', (_) => false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inriaSans(
                              fontSize: screenHeight * 0.0225,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
