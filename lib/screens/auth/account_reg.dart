import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
    });
  }

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
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
            child: CustomPaint(
          painter: OrangePainter(),
          child: Center(
              child: Column(
            children: [
              //sign up texts
              Padding(
                padding: EdgeInsets.fromLTRB(0, screenHeight * 0.05, 0, 0),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, screenHeight * 0.01, 0, 0),
                child: Text(
                  'First Create Your Account',
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.025,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),

              //logo
              Image.asset('lib/images/animalReconnect_logo.png',
                  height: screenHeight * 0.3),

              Expanded(
                  child: Column(children: [
                //username text field
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.12, 0, screenWidth * 0.12, 0),
                  child: TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      contentPadding: EdgeInsets.fromLTRB(
                          10, screenHeight * 0.01, 10, screenHeight * 0.01),
                    ),
                  ),
                ),
                //email text field
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.12, 0, screenWidth * 0.12, 0),
                  child: TextField(
                    controller: _email,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      contentPadding: EdgeInsets.fromLTRB(
                          10, screenHeight * 0.01, 10, screenHeight * 0.01),
                    ),
                  ),
                ),
                //password text field
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.12, 0, screenWidth * 0.12, 0),
                  child: TextField(
                    controller: _password,
                    obscureText: _isPasswordObscured,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      contentPadding: EdgeInsets.fromLTRB(
                          10, screenHeight * 0.015, 10, screenHeight * 0.015),
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
                //confirm text field
                Padding(
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.12, 0,
                      screenWidth * 0.12, screenHeight * 0.017),
                  child: TextField(
                    controller: _confirmPassword, // Step 2
                    obscureText: _isConfirmPasswordObscured,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      contentPadding: EdgeInsets.fromLTRB(
                          10, screenHeight * 0.015, 10, screenHeight * 0.015),
                      suffixIcon: IconButton(
                        icon: Icon(
                          size: screenHeight * 0.025,
                          _isConfirmPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                ),
                //sign up button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                  child: createButton(
                      screenWidth * 0.8,
                      screenHeight * 0.06,
                      () => handleSignUp(),
                      'SIGN UP',
                      Colors.white,
                      screenHeight * 0.0225,
                      const Color.fromARGB(255, 247, 184, 1),
                      const Color.fromARGB(255, 241, 132, 1),
                      Colors.transparent,
                      Colors.transparent),
                ),
              ])),

              //divider
              Container(
                width: screenWidth * 0.9, // Adjust the width of the line
                height: 1,
                color: Colors.grey,
              ),

              //already ahve an account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? |',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.016,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login/', (_) => false);
                    },
                    child: Text(
                      'Login',
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
          )),
        )),
      ),
    );
  }

  void handleSignUp() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final username = _username.text.trim();
    final confirmPassword = _confirmPassword.text.trim();
    // Check if any field is empty
    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Additional checks for email format, password length, etc.
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters long')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    try {
      // Create user with email and password
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user's ID
      String userId = userCredential.user!.uid;

      // Store the username in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'id': userId,
        'username': username,
        'email': email,
      });

      // Navigate to another screen if needed
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/verifyEmail/', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class OrangePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    drawShape1(canvas, size, paint, Colors.orange.withAlpha(150));
    drawShape2(canvas, size, paint, Colors.orange.withAlpha(150));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  void drawShape1(Canvas canvas, Size size, Paint paint, Color color) {
    paint.color = color;
    Path path = Path();
    path.moveTo(size.width, 0);
    path.quadraticBezierTo(
        size.width / 2, size.height / 2, -100, size.height / 4);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height - size.width * 0.2), 150, paint);
  }

  void drawShape2(Canvas canvas, Size size, Paint paint, Color color) {
    paint.color = color;
    Path path = Path();
    path.moveTo(size.width, 0);
    path.quadraticBezierTo(
        size.width / 2, size.height / 2, -100, size.height / 4);
    canvas.drawCircle(Offset(size.width * 0.2, 0), 150, paint);
  }
}
