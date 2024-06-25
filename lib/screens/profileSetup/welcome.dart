import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool canPop = Navigator.of(context).canPop();
    return SafeArea(
      child: PopScope(
        canPop: canPop,
        child: Scaffold(
          appBar: AppBar(),
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Image.asset('lib/images/animalReconnect_logo.png',
                    height: screenHeight * 0.15), // Logo size adjustment
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Welcome to Animal Reconnect.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSans(
                    fontSize: screenHeight * 0.025,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Please follow these Rules.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSans(
                    color: Colors.grey.shade700,
                    fontSize: screenHeight * 0.02,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                ruleTile(
                    screenHeight,
                    screenWidth,
                    'lib/images/welcome_image.png',
                    'Authenticity is key.',
                    'Ensure that your pictures, age, and biography accurately reflect the real you.'),
                ruleTile(
                    screenHeight,
                    screenWidth,
                    'lib/images/welcome_image.png',
                    'Prioritize your safety.',
                    'Exercise caution before sharing personal details.'),
                ruleTile(
                    screenHeight,
                    screenWidth,
                    'lib/images/welcome_image.png',
                    'Maintain respect.',
                    'Treat others with the same respect and kindness you would expect in return.'),
                ruleTile(
                    screenHeight,
                    screenWidth,
                    'lib/images/welcome_image.png',
                    'Take action.',
                    'Always report bad behavior.'),
                SizedBox(height: screenHeight * 0.02),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, screenHeight * 0.0225, 0, screenHeight * 0.0225),
                  child: createButton(screenWidth * 0.8, screenHeight * 0.06,
                      () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/homepage/', (_) => false);
                  },
                      'I AGREE',
                      Colors.white,
                      screenHeight * 0.0225,
                      const Color.fromARGB(255, 247, 184, 1),
                      const Color.fromARGB(255, 241, 132, 1),
                      Colors.transparent,
                      Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget ruleTile(double screenHeight, double screenWidth, String imagePath,
      String title, String description) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          screenWidth * 0.1, 0, screenWidth * 0.1, screenHeight * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, height: screenHeight * 0.06), // Icon size
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inriaSans(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold)),
                Text(description,
                    style: GoogleFonts.inriaSans(
                        color: Colors.grey.shade700,
                        fontSize: screenHeight * 0.02)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
