import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BirthDate extends StatefulWidget {
  final bool isEditMode;

  const BirthDate(
      {super.key, required this.isEditMode});

  @override
  State<BirthDate> createState() => _BirthDate();
}

class _BirthDate extends State<BirthDate> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  final int totalDigits = 8;

  @override
  void initState() {
    _controllers = List.generate(totalDigits, (_) => TextEditingController());
    _focusNodes = List.generate(totalDigits, (_) => FocusNode());

    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
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
                    'My date of\nbirth is',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...List.generate(
                        4,
                        (index) => buildInputField(index, _controllers[index],
                            _focusNodes[index], 'Y')),
                    Text('/',
                        style: GoogleFonts.inriaSans(
                            fontSize: screenHeight * 0.03,
                            color: Colors.black)),
                    ...List.generate(
                        2,
                        (index) => buildInputField(
                            index + 4,
                            _controllers[index + 4],
                            _focusNodes[index + 4],
                            'M')),
                    Text('/',
                        style: GoogleFonts.inriaSans(
                            fontSize: screenHeight * 0.03,
                            color: Colors.black)),
                    ...List.generate(
                        2,
                        (index) => buildInputField(
                            index + 6,
                            _controllers[index + 6],
                            _focusNodes[index + 6],
                            'D')),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.03, 0, screenHeight * 0.075),
                  child: Text(
                    'Your age will be private',
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
                      String year =
                          _controllers.sublist(0, 4).map((c) => c.text).join();
                      String month =
                          _controllers.sublist(4, 6).map((c) => c.text).join();
                      String day =
                          _controllers.sublist(6, 8).map((c) => c.text).join();
                      String formattedDate = '$year-$month-$day';
                      final birthDate = formattedDate;
                      if (birthDate.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill in the field')),
                        );
                        return;
                      }
                      if (isDate(birthDate, "yyyy-MM-dd")) {
                        if (calculateAge(DateTime.parse(birthDate)) < 18) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('You must be at least 18 years old')),
                          );
                          return;
                        }
                        if (widget.isEditMode) {
                          if (mounted) {
                            Navigator.of(context).pop(birthDate);
                          }
                        } else {
                          String? userId =
                              FirebaseAuth.instance.currentUser?.uid;
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .update({
                            'birthDate': birthDate,
                          });

                          if (context.mounted) {
                            Navigator.of(context).pushNamed(
                              '/setUpGender/',
                              arguments: {
                                'isEditMode': false,
                                'currentGender': 'NONE',
                              },
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please input in a valid date')),
                        );
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isDate(String input, String format) {
    try {
      DateFormat(format).parseStrict(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  buildInputField(int index, TextEditingController controller,
      FocusNode focusNode, String inputHint) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
        width: 30,
        height: screenHeight * 0.05,
        alignment: Alignment.center,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (controller.text.isEmpty && index > 0) {
                _controllers[index - 1].text = "";
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              } else if (controller.text.isNotEmpty) {
                _controllers[index].text = "";
                FocusScope.of(context).requestFocus(_focusNodes[index]);
              }
            } else if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              FocusScope.of(context).unfocus();
            }
          },
          child: TextFormField(
            enableInteractiveSelection: false,
            readOnly: _controllers[index].text.isNotEmpty &&
                !_focusNodes[index].hasFocus,
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: GoogleFonts.inriaSans(fontSize: screenHeight * 0.03),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            maxLength: 1,
            onTap: () {
              if (_controllers[index].text.isEmpty ||
                  _controllers[index].text.isNotEmpty) {
                FocusNode firstEmpty = findFirstEmpty();
                if (firstEmpty != _focusNodes[index]) {
                  FocusScope.of(context).requestFocus(firstEmpty);
                }
              }
            },
            onChanged: (value) {
              if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              } else if (value.length == 1 && index < totalDigits - 1) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              }
              bool allFilled = _controllers
                  .every((controller) => controller.text.isNotEmpty);
              if (allFilled) {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: InputDecoration(
              counterText: "",
              hintText: inputHint,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ));
  }

  FocusNode findFirstEmpty() {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        return _focusNodes[i];
      }
    }
    return _focusNodes.last; // Return the last one if none are empty
  }
}
