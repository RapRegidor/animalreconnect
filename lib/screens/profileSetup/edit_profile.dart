import 'package:animalreconnect/controller/utils.dart';
import 'package:animalreconnect/screens/auth/account_reg.dart';
import 'package:animalreconnect/screens/petProfile/add_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  final String userId;
  final String imageUrl;
  final String username;
  final String bio;
  final String email;
  final String gender;
  final String birthDate;
  final Timestamp timestamp;

  Profile(
      {required this.userId,
      required this.imageUrl,
      required this.username,
      required this.bio,
      required this.email,
      required this.gender,
      required this.birthDate,
      required this.timestamp});
}

class EditUserProfile extends StatefulWidget {
  final String? userId;

  const EditUserProfile({
    super.key,
    required this.userId,
  });

  @override
  State<EditUserProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditUserProfile> {
  late Future<Profile> userProfileFuture;
  late String profileId;
  late TextEditingController _bioController;
  String? _username;
  String? _gender;
  bool? _showPref;
  String? _birthDate;

  @override
  void initState() {
    super.initState();
    profileId = widget.userId!;
    _bioController = TextEditingController();
    userProfileFuture = fetchProfile(profileId);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<Profile> fetchProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _showPref = prefs.getBool('showGender');
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    var data = userDoc.data() as Map<String, dynamic>;
    String imageUrl = data['imageUrl'] as String? ??
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png';
    String username = data['username'] as String? ?? 'Anonymous';
    String bio =
        data['profileDescription'] as String? ?? 'Pleased to meet you!';
    String email = data['email'] as String;
    String gender = data['gender'] as String? ?? 'Not specified';
    String birthDate = data['birthDate'];
    Timestamp timestamp = data['timestamp'];
    _bioController.text = bio;
    _username = username;
    _gender = gender;
    _birthDate = birthDate;
    return Profile(
        userId: userId,
        imageUrl: imageUrl,
        username: username,
        bio: bio,
        email: email,
        gender: gender,
        birthDate: birthDate,
        timestamp: timestamp);
  }

  Uint8List? _image;
  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  void updateProfile() {
    setState(() {
      userProfileFuture = fetchProfile(profileId);
    });
  }

  void updateUsername(String newUsername) {
    setState(() {
      _username = newUsername;
    });
  }

  void updateGender(Map<String, dynamic> gender) {
    String selectedGender = gender['gender'];
    bool showGenderPref = gender['pref'];
    setState(() {
      _gender = selectedGender;
      _showPref = showGenderPref;
    });
  }

  void updateBirthDate(String birthDate) {
    setState(() {
      _birthDate = birthDate;
    });
  }

  Future<void> saveProfile() async {
    String? userId = widget.userId;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseStorage storage = FirebaseStorage.instance;
    if (_image != null) {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      var data = userDoc.data() as Map<String, dynamic>;
      if (data.containsKey('imageUrl') &&
          data['imageUrl'].toString().isNotEmpty) {
        Reference storageRef = storage.refFromURL(data['imageUrl']);
        await storageRef.delete();
      }
      Reference newStorageRef =
          storage.ref().child('userProfilePictures').child('$userId.png');
      UploadTask uploadTask = newStorageRef.putData(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      await firestore.collection('users').doc(userId).update({
        'username': _username,
        'profileDescription': _bioController.text,
        'imageUrl': downloadUrl,
        'birthDate': _birthDate,
        'gender': _gender
      });
    } else {
      await firestore.collection('users').doc(userId).update({
        'username': _username,
        'profileDescription': _bioController.text,
        'birthDate': _birthDate,
        'gender': _gender
      });
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showGender', _showPref!);
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/homepage/', (_) => false,
          arguments: {'initialTabIndex': 4});
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              saveProfile();
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: CustomPaint(
          painter: OrangePainter(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Center(
              child: Column(
                children: [
                  FutureBuilder<Profile>(
                    future: userProfileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        String formattedDate = DateFormat('yyyy-MM-dd')
                            .format(snapshot.data!.timestamp.toDate());
                        return Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 64,
                                  backgroundImage: _image != null
                                      ? MemoryImage(_image!)
                                      : NetworkImage(snapshot.data!.imageUrl)
                                          as ImageProvider,
                                ),
                                Positioned(
                                  bottom: -10,
                                  left: 80,
                                  child: IconButton(
                                    onPressed: () {
                                      selectImage();
                                    },
                                    icon: const Icon(Icons.add_a_photo),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _username ?? snapshot.data!.username,
                                  style: GoogleFonts.inriaSans(
                                    fontSize: screenHeight * 0.03,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await Navigator.of(context)
                                        .pushNamed('/setUpUsername/',
                                            arguments: {
                                          'isEditMode': true,
                                          'currentUsername': _username ??
                                              snapshot.data!.username,
                                        });
                                    if (result != null && result is String) {
                                      updateUsername(result);
                                    }
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Member since $formattedDate',
                              style: GoogleFonts.inriaSans(
                                fontSize: screenHeight * 0.02,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: screenWidth * 0.9,
                              height: 1,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 25),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inriaSans(
                                    fontSize: screenHeight * 0.02,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    const TextSpan(
                                      text: 'Email: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: snapshot.data!.email,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inriaSans(
                                          fontSize: screenHeight * 0.02,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Gender: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: _gender ??
                                                snapshot.data!.gender,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result =
                                          await Navigator.of(context).pushNamed(
                                        '/setUpGender/',
                                        arguments: {
                                          'isEditMode': true,
                                          'currentGender':
                                              _gender ?? snapshot.data!.gender,
                                        },
                                      );
                                      if (result != null &&
                                          result is Map<String, dynamic>) {
                                        updateGender(result);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inriaSans(
                                          fontSize: screenHeight * 0.02,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          const TextSpan(
                                            text: 'Birthdate: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: _birthDate ??
                                                snapshot.data!.birthDate,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.of(context)
                                          .pushNamed('/setUpBirthDate/',
                                              arguments: {
                                            'isEditMode': true,
                                          });
                                      if (result != null && result is String) {
                                        updateBirthDate(result);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: screenWidth * 0.9,
                              height: 1,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 30),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: TextField(
                                        controller: _bioController,
                                        maxLines: 7,
                                        maxLength: 500,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Bio',
                                          hintText: 'Put your profile bio here',
                                        ),
                                        style: GoogleFonts.inriaSans(
                                          fontSize: screenHeight * 0.02,
                                        ),
                                        onTap: () {
                                          _bioController.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset:
                                                    _bioController.text.length),
                                          );
                                        },
                                        inputFormatters: [NewFormatter()],
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (value) {
                                          FocusScope.of(context).unfocus();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const CircularProgressIndicator(
                            color: Colors.grey);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
