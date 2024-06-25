import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstName extends StatefulWidget {
  const FirstName({super.key});

  @override
  State<FirstName> createState() => _FirstName();
}

class _FirstName extends State<FirstName> {
  late final TextEditingController _firstName;

  @override
  void initState() {
    _firstName = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _firstName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PopScope(
          canPop: canPop,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.1, 0, screenHeight * 0.075),
                  child: Text(
                    'My first\nname is',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: _firstName,
                  decoration: InputDecoration(
                    hintText: 'First name',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.01, 0, screenHeight * 0.03),
                  child: Text(
                    'You will not be able to change it after finishing the profile setup',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.0175,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    gradient: const LinearGradient(colors: [
                      Color.fromARGB(255, 247, 184, 1),
                      Color.fromARGB(255, 241, 132, 1)
                    ]),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final firstName = _firstName.text.trim();
                      if (firstName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill in the field')),
                        );
                        return;
                      }
                      String? userId = FirebaseAuth.instance.currentUser?.uid;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'firstName': firstName,
                      });
                      if (context.mounted) {
                        Navigator.of(context).pushNamed(
                          '/setUpBirthDate/',
                          arguments: {
                            'isEditMode': false,
                            'currentBirthDate': '',
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inriaSans(
                        fontSize: screenHeight * 0.0225,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                  child: SizedBox(
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.06,
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
