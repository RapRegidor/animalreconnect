import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Gender extends StatefulWidget {
  final bool isEditMode;
  final String currentGender;
  const Gender(
      {super.key, required this.isEditMode, required this.currentGender});

  @override
  State<Gender> createState() => _Gender();
}

class _Gender extends State<Gender> {
  List<Color> textColors = List.filled(3, Colors.black);
  List<Color> primaries = List.filled(3, const Color.fromARGB(0, 0, 0, 0));
  List<Color> secondaries = List.filled(3, const Color.fromARGB(0, 0, 0, 0));
  List<Color> backgrounds = List.filled(3, Colors.white);
  bool pref = false; //to show
  String gender = "NONE";

  @override
  void initState() {
    super.initState();
    gender = widget.currentGender;
    int initialIndex = getGenderIndex(widget.currentGender);
    if (initialIndex != -1) {
      selected(initialIndex);
    }
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    pref = await getPrefs();
    setState(() {});
  }

  Future<bool> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    bool showPref = prefs.getBool('showGender') ?? false;
    return showPref;
  }

  int getGenderIndex(String gender) {
    switch (gender.toUpperCase()) {
      case 'WOMAN':
        return 0;
      case 'MAN':
        return 1;
      case 'NONBINARY':
        return 2;
      default:
        return -1;
    }
  }

  void selected(int index) {
    setState(() {
      textColors =
          List.generate(3, (i) => i == index ? Colors.white : Colors.black);
      primaries = List.generate(
          3,
          (i) => i == index
              ? const Color.fromARGB(0, 0, 0, 0)
              : const Color.fromARGB(0, 0, 0, 0));
      secondaries = List.generate(
          3,
          (i) => i == index
              ? const Color.fromARGB(0, 0, 0, 0)
              : const Color.fromARGB(0, 0, 0, 0));
      backgrounds =
          List.generate(3, (i) => i == index ? Colors.grey : Colors.white);
      gender = index == 0
          ? "WOMAN"
          : index == 1
              ? "MAN"
              : "NONBINARY";
    });
  }

  Future handleGender(String gender, pref) async {
    if (gender != "NONE") {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('showGender', pref);
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'gender': gender,
      });
      if (mounted) {
        Navigator.of(context).pushNamed('/setUpProfilePicture/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one of the options')),
      );
    }
  }

  Future saveGender(String gender, pref) async {
    if (mounted) {
      Navigator.of(context).pop({'gender': gender, 'pref': pref});
    }
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
                    'I am a',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  child: createButton(screenWidth * 0.8, screenHeight * 0.06,
                      () {
                    selected(0);
                  },
                      'WOMAN',
                      textColors[0],
                      screenHeight * 0.0225,
                      primaries[0],
                      secondaries[0],
                      backgrounds[0],
                      Colors.black),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  child: createButton(screenWidth * 0.8, screenHeight * 0.06,
                      () {
                    selected(1);
                  }, 'MAN', textColors[1], screenHeight * 0.0225, primaries[1],
                      secondaries[1], backgrounds[1], Colors.black),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  child: createButton(screenWidth * 0.8, screenHeight * 0.06,
                      () {
                    selected(2);
                  },
                      'NONBINARY',
                      textColors[2],
                      screenHeight * 0.0225,
                      primaries[2],
                      secondaries[2],
                      backgrounds[2],
                      Colors.black),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.08, 0, screenHeight * 0.01),
                  child: Row(
                    children: [
                      Checkbox(
                          value: pref,
                          onChanged: (bool? value) {
                            setState(() {
                              pref = value ?? false;
                            });
                          }),
                      const SizedBox(width: 10),
                      Text(
                        'Show my gender on my profile',
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                createButton(screenWidth * 0.8, screenHeight * 0.06, () {
                  widget.isEditMode
                      ? saveGender(gender, pref)
                      : handleGender(gender, pref);
                },
                    widget.isEditMode ? 'Save' : 'Continue',
                    Colors.white,
                    screenHeight * 0.0225,
                    const Color.fromARGB(255, 247, 184, 1),
                    const Color.fromARGB(255, 241, 132, 1),
                    Colors.transparent,
                    Colors.transparent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
