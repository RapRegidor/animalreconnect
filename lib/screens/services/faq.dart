import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ShowFAQ extends StatefulWidget {
  const ShowFAQ({super.key});

  @override
  State<ShowFAQ> createState() => _ShowFAQState();
}

class _ShowFAQState extends State<ShowFAQ> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 242, 241, 241),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'We\'re here to assist you with anything and everything related to our Animal Reconnect pet re-homing and adoption app',
                    style: GoogleFonts.inriaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: screenHeight * 0.03),
                    textAlign: TextAlign.justify,
                  )),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 30),
                  child: Text(
                    'FAQ',
                    style: GoogleFonts.inriaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: screenHeight * 0.02),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    width: screenWidth * 0.9,
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildFaqItem("Why Should I Choose to Adopt a Pet?",
                      "Adopting a pet saves lives and provides a loving home to an animal in need. It also helps to reduce the number of animals in shelters."),
                  Container(
                    width: screenWidth,
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildFaqItem("How Can I Prepare My Pet for Re-homing?",
                      "Preparing your pet for re-homing involves ensuring they are healthy, well-behaved, and have up-to-date vaccinations. Providing information about their habits and preferences can also help."),
                  Container(
                    width: screenWidth,
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildFaqItem("How Can We Meet a Potential Pet Safely?",
                      "Meeting a potential pet safely involves arranging a neutral location, observing the pet's behavior, and ensuring that both the pet and potential owner feel comfortable."),
                  Container(
                    width: screenWidth,
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildFaqItem("What do Care Levels mean?",
                      "Care levels indicate the amount of attention and care a pet needs. Higher care levels may require more time, resources, and experience."),
                  Container(
                    width: screenWidth,
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildFaqItem("What Should First-Time Pet Adopters Know?",
                      "First-time pet adopters should understand the commitment involved in pet ownership, including the time, effort, and financial responsibilities."),
                  Container(
                    width: screenWidth,
                    height: 1,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Stuck? We\'re just an email away.',
                style: GoogleFonts.inriaSans(
                    fontWeight: FontWeight.bold, fontSize: screenHeight * 0.02),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, screenHeight * 0.01, 0, screenHeight * 0.0225),
                child: createButton(screenWidth * 0.8, screenHeight * 0.06, () {
                  sendEmail();
                },
                    'Send a message',
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
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }

  void sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'helpdesk@gmail.com',
      query: 'subject=Help Needed&body=',
    );

    try {
      if (await canLaunchUrlString(emailLaunchUri.toString())) {
        await launchUrlString(emailLaunchUri.toString());
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error launching email: $e');
    }
  }
}
