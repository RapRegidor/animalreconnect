import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Username extends StatefulWidget {
  final bool isEditMode;
  final String currentUsername;

  const Username({
    super.key,
    required this.isEditMode,
    required this.currentUsername,
  });

  @override
  State<Username> createState() => _Username();
}

class _Username extends State<Username> {
  late final TextEditingController _username;

  @override
  void initState() {
    _username = TextEditingController(
        text: widget.isEditMode ? widget.currentUsername : '');
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: widget.isEditMode
          ? AppBar(
              title: const Text('Edit Username'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, screenHeight * 0.1, 0, screenHeight * 0.075),
                child: Text(
                  'My username\nis',
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, screenHeight * 0.075),
                child: TextField(
                  controller: _username,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
                    final username = _username.text.trim();
                    if (username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill in the field')),
                      );
                      return;
                    }
                    if (widget.isEditMode) {
                      Navigator.of(context).pop(username);
                    } else {
                      String? userId = FirebaseAuth.instance.currentUser?.uid;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'username': username,
                      });
                      if (context.mounted) {
                        Navigator.of(context).pushNamed('/setUpFirstName/');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    widget.isEditMode ? 'Save' : 'Continue',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.0225,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!widget.isEditMode)
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
                )
            ],
          ),
        ),
      ),
    );
  }
}
