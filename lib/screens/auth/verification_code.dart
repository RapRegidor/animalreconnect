import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationEmail extends StatefulWidget {
  const VerificationEmail({super.key});

  @override
  State<VerificationEmail> createState() => _VerificationEmail();
}

class _VerificationEmail extends State<VerificationEmail> {
  bool isVerified = false;
  bool canResend = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (!isVerified) {
      sendVerification();
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkVerified(),
      );
    } else {
      destination();
    }
  }

  Future<void> destination() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser!;
    bool firstTimeVerified = (prefs.getBool('firstTimeVerified') ?? false);
    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

    if (!data.containsKey('id')) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'id': user.uid,
      });
    }
    if (data.containsKey('username') &&
        data['username'].toString().isNotEmpty) {
      if (data.containsKey('firstName') &&
          data['firstName'].toString().isNotEmpty &&
          data.containsKey('birthDate') &&
          data['birthDate'].toString().isNotEmpty &&
          data.containsKey('gender') &&
          data['gender'].toString().isNotEmpty) {
        if (!firstTimeVerified) {
          await prefs.setBool('firstTimeVerified', true);
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/welcome/', (_) => false);
          }
        } else {
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/homepage/', (_) => false);
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/setUpFirstName/', (_) => false);
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/setUpUsername/',
          (_) => false,
          arguments: {
            'isEditMode': false,
            'currentUsername': '',
          },
        );
      }
    }
  }

  Future checkVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    if (!mounted) return;
    setState(() {
      isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isVerified) {
      timer?.cancel();
    }
  }

  Future sendVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      setState(() => canResend = false);
      await user.sendEmailVerification();
      setState(() => canResend = true);
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    if (isVerified) {
      return FutureBuilder<void>(
        future: destination(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          // Handle the snapshot state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Container();
          }
        },
      );
    } else {
      return PopScope(
        canPop: false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Verify Email'),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.0, screenHeight * 0.1, 8.0, 8.0),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Please check your email\nfor verification',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
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
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 247, 184, 1),
                            Color.fromARGB(255, 241, 132, 1),
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: canResend ? sendVerification : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Resend Email',
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
                    child: SizedBox(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.075,
                      child: ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/login/', (_) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
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
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
