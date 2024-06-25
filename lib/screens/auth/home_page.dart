import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
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
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login/', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent),
                child: Text(
                  'Sign out',
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.0225,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
