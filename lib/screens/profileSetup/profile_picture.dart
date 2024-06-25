import 'dart:typed_data';
import 'package:animalreconnect/controller/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePicture extends StatefulWidget {
  const ProfilePicture({super.key});

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uint8List? _image;
  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  Future<void> saveProfile() async {
    if (_image != null) {
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('userProfilePictures')
            .child('$userId.png');
        UploadTask uploadTask = storageRef.putData(_image!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'imageUrl': downloadUrl,
        });
      } catch (e) {
        // ignore: avoid_print
        print('Error saving profile picture: $e');
      }
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
                    'Set up your profile picture',
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Stack(children: [
                    _image != null
                        ? CircleAvatar(
                            radius: 64, backgroundImage: MemoryImage(_image!))
                        : const CircleAvatar(
                            radius: 64,
                            backgroundImage: NetworkImage(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png')),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                          onPressed: () {
                            selectImage();
                          },
                          icon: const Icon(Icons.add_a_photo)),
                    ),
                  ]),
                ),
                const SizedBox(
                  height: 50,
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
                      saveProfile();
                      String userId = FirebaseAuth.instance.currentUser!.uid;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.of(context).pushNamed('/welcome/');
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
