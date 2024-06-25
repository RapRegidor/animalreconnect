import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class PetProfile {
  String id;
  String ownerId;
  String name;
  String species;
  String gender;
  int? age;
  double? weight;
  String careLevel;
  String bio;
  String profileImageUrl;
  List<String> galleryImageUrls;
  String location;

  PetProfile(
      {required this.id,
      required this.ownerId,
      required this.name,
      required this.species,
      required this.gender,
      required this.age,
      required this.weight,
      required this.careLevel,
      required this.bio,
      this.profileImageUrl = '',
      this.galleryImageUrls = const [],
      required this.location});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'gender': gender,
      'age': age,
      'weight': weight,
      'careLevel': careLevel,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'galleryImageUrls': galleryImageUrls,
      'location': location,
    };
  }
}

class CreatePetProfile extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  final Map<String, dynamic>? petData;

  const CreatePetProfile({
    super.key,
    required this.onProfileUpdated,
    this.petData,
  });

  @override
  State<CreatePetProfile> createState() => _CreatePetProfileState();
}

class _CreatePetProfileState extends State<CreatePetProfile> {
  String? petId;
  List<dynamic> images = [];
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _petName;
  late final TextEditingController _petAge;
  late final TextEditingController _petWeight;
  late final TextEditingController _petBio;
  bool isAgeUnknown = false;
  bool isWeightUnknown = false;
  bool imagesModified = false;
  bool isProfileImageSwitched = false;
  String? _selectedSpecies;
  final List<String> _speciesOptions = ['Cat', 'Dog', 'Others'];
  String? _selectedGender;
  final List<String> _genderOptions = ['Female', 'Male'];
  String? _selectedCare;
  final List<String> _careOptions = [
    '1 - Basic Care',
    '2 - Standard Care',
    '3 - Moderate Care',
    '4 - Advanced Care',
    '5 - Specialized Care'
  ];
  String? _selectedLocation;
  final List<String> _locationOptions = [
    'Brooklyn',
    'Queens',
    'Manhattan',
    'Bronx',
    'Staten Island'
  ];
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _petName = TextEditingController();
    _petAge = TextEditingController();
    _petWeight = TextEditingController();
    _petBio = TextEditingController();

    if (widget.petData != null) {
      petId = widget.petData!['id']; 
      _petName.text = widget.petData!['name'];
      _selectedSpecies = widget.petData!['species'];
      _selectedGender = widget.petData!['gender'];
      if (widget.petData!['age'] != null) {
        _petAge.text = widget.petData!['age'].toString();
      }
      if (widget.petData!['weight'] != null) {
        _petWeight.text = widget.petData!['weight'].toString();
      }
      _selectedCare = widget.petData!['careLevel'];
      _petBio.text = widget.petData!['bio'];
      _selectedLocation = widget.petData!['location'];

      if (widget.petData!['galleryImageUrls'] != null) {
        images.addAll(List<String>.from(widget.petData!['galleryImageUrls']));
      }
    }
  }

  @override
  void dispose() {
    _petName.dispose();
    _petAge.dispose();
    _petWeight.dispose();
    _petBio.dispose();
    super.dispose();
  }

  Future<void> addImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (file.existsSync()) {
        setState(() {
          images.add(file);
          imagesModified = true;
          if (images.length > 9) {
            images.removeLast();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to add image: File does not exist')),
          );
        }
      }
    }
  }

  void removeImage(int index) {
    setState(() {
      if (images[index] is String) {
        deleteImageFromStorage(images[index] as String);
      }
      images.removeAt(index);
      imagesModified = true;
    });
  }

  void swapWithFirst(int index) async {
    if (index != 0) {
      setState(() {
        var firstImage = images[0];
        images[0] = images[index];
        images[index] = firstImage;
        isProfileImageSwitched = true;
      });


      String newProfileImageUrl = images[0] is String
          ? images[0]
          : await uploadPetImage(images[0], currentUser!.uid);

      List<String> galleryImageUrls = images
          .map((image) {
            return image is String ? image : '';
          })
          .where((url) => url.isNotEmpty)
          .toList();

      if (images[0] is File) {
        newProfileImageUrl = await uploadPetImage(images[0], currentUser!.uid);
      }

      if (widget.petData != null) {
        galleryImageUrls = [newProfileImageUrl, ...galleryImageUrls.skip(1)];


        await FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.petData!['id'])
            .update({
          'profileImageUrl': newProfileImageUrl,
          'galleryImageUrls': galleryImageUrls,
        });

        setState(() {
          widget.petData!['profileImageUrl'] = newProfileImageUrl;
          widget.petData!['galleryImageUrls'] = galleryImageUrls;
        });
      }
    }
  }

  Future<void> savePetProfile(PetProfile petProfile) async {
    final docRef =
        FirebaseFirestore.instance.collection('pets').doc(petProfile.id);
    await docRef.set(petProfile.toMap(), SetOptions(merge: true));
  }

  Future<String> uploadPetImage(dynamic image, String userId) async {
    String filePath =
        'pets/$userId/${DateTime.now().millisecondsSinceEpoch}.png';
    final ref = FirebaseStorage.instance.ref().child(filePath);

    if (image is File) {
      final result = await ref.putFile(image);
      return await result.ref.getDownloadURL();
    } else if (image is String) {
      return image;
    } else {
      throw 'Invalid image type';
    }
  }

  Future<void> createOrUpdatePetProfile() async {
    if (_selectedSpecies == null ||
        _selectedGender == null ||
        _selectedCare == null ||
        _selectedLocation == null ||
        _petName.text.isEmpty ||
        images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      List<String> galleryImageUrls = widget.petData != null
          ? List<String>.from(widget.petData!['galleryImageUrls'])
          : [];

      if (images.isNotEmpty) {
        if (imagesModified) {
          String profImageUrl =
              await uploadPetImage(images.first, currentUser!.uid);

          galleryImageUrls.clear();

          for (int i = 1; i < images.length; i++) {
            String imageUrl = await uploadPetImage(images[i], currentUser!.uid);
            galleryImageUrls.add(imageUrl);
          }

          galleryImageUrls.insert(0, profImageUrl);
        } else {
          if (widget.petData != null) {
            galleryImageUrls =
                List<String>.from(widget.petData!['galleryImageUrls']);
          }
        }
      }

      String profileImageUrl =
          galleryImageUrls.isNotEmpty ? galleryImageUrls[0] : '';

      petId ??= FirebaseFirestore.instance.collection('pets').doc().id;
      PetProfile profile = PetProfile(
        id: petId!,
        ownerId: currentUser!.uid,
        name: _petName.text,
        species: _selectedSpecies!,
        gender: _selectedGender!,
        age: isAgeUnknown ? 0 : int.tryParse(_petAge.text),
        weight: isWeightUnknown ? 0 : double.tryParse(_petWeight.text),
        careLevel: _selectedCare!,
        bio: _petBio.text,
        location: _selectedLocation!,
        profileImageUrl: profileImageUrl,
        galleryImageUrls: galleryImageUrls,
      );

      await savePetProfile(profile);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        widget.onProfileUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  void deletePetProfile() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot petDoc =
        await firestore.collection('pets').doc(petId).get();

    if (petDoc.exists && petDoc.data() != null) {
      var petData = petDoc.data() as Map<String, dynamic>;
      List<String> galleryImageUrls =
          List<String>.from(petData['galleryImageUrls'] ?? []);

      await deleteImagesFromStorage(galleryImageUrls);

      await firestore.collection('pets').doc(petId).delete();
      widget.onProfileUpdated();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> deleteImagesFromStorage(List<String> imageUrls) async {
    for (String url in imageUrls) {
      await deleteImageFromStorage(url);
    }
  }

  Future<void> deleteImageFromStorage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      try {
        Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        // ignore: avoid_print
        print('Error deleting image from storage: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Profile'),
        actions: [
          TextButton(
            onPressed: () async {
              await createOrUpdatePetProfile();
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Add images of your pet.',
                style: GoogleFonts.inriaSans(
                  fontSize: screenHeight * 0.0175,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'The first photo will be set as the profile picture.\nDouble-tap any photo to make it the new profile picture.',
                style: GoogleFonts.inriaSans(
                  fontSize: screenHeight * 0.015,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              //pictures
              SizedBox(
                height: screenHeight * 0.625,
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    if (index < images.length) {
                      return GestureDetector(
                        onDoubleTap: () => swapWithFirst(index),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: images[index] is File
                                      ? FileImage(images[index] as File)
                                      : NetworkImage(images[index] as String)
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () => removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 107, 99, 99),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (index == images.length && index < 9) {
                      return GestureDetector(
                        onTap: addImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      );
                    } else {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }
                  },
                ),
              ),

              //divider
              Container(
                width: screenWidth * 0.9,
                height: 1,
                color: Colors.grey,
              ),
              //pet profile
              Padding(
                padding: EdgeInsets.fromLTRB(screenHeight * 0.021,
                    screenHeight * 0.01, 0, screenHeight * 0.01),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pet Profile",
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              //pet name
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 20, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Pet Name:",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _petName,
                        maxLength: 16,
                        decoration: const InputDecoration(
                          labelText: 'Enter Pet Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //Species
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Species: ",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select One'),
                        value: _selectedSpecies,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: screenHeight * 0.02,
                        ),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSpecies = newValue;
                          });
                        },
                        items: _speciesOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              //gender
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Gender: ",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select One'),
                        value: _selectedGender,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: screenHeight * 0.02,
                        ),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        items: _genderOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              //age
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Age:",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _petAge,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter pet age',
                          border: OutlineInputBorder(),
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isAgeUnknown,
                      ),
                    ),
                    Checkbox(
                      value: isAgeUnknown,
                      onChanged: (bool? value) {
                        setState(() {
                          isAgeUnknown = value ?? false;
                          if (isAgeUnknown) {
                            _petAge.clear();
                          }
                        });
                      },
                    ),
                    const Text('Unknown'),
                  ],
                ),
              ),

              //weight
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Weight (lbs): ",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _petWeight,
                        maxLength: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter pet weight',
                          border: OutlineInputBorder(),
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isWeightUnknown,
                      ),
                    ),
                    Checkbox(
                      value: isWeightUnknown,
                      onChanged: (bool? value) {
                        setState(() {
                          isWeightUnknown = value ?? false;
                          if (isWeightUnknown) {
                            _petWeight.clear();
                          }
                        });
                      },
                    ),
                    const Text('Unknown'),
                  ],
                ),
              ),

              //location
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Location: ",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select One'),
                        value: _selectedLocation,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: screenHeight * 0.02,
                        ),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLocation = newValue;
                          });
                        },
                        items: _locationOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              //Care level
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 15, screenWidth * 0.05, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Care level: ",
                        style: GoogleFonts.inriaSans(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select One'),
                        value: _selectedCare,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: screenHeight * 0.02,
                        ),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCare = newValue;
                          });
                        },
                        items: _careOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              //divider
              Container(
                width: screenWidth * 0.9,
                height: 1,
                color: Colors.grey,
              ),
              //pet bio
              Padding(
                padding: EdgeInsets.fromLTRB(screenHeight * 0.021,
                    screenHeight * 0.01, 0, screenHeight * 0.01),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pet Bio",
                    style: GoogleFonts.inriaSans(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 20, screenWidth * 0.05, 20),
                child: TextField(
                  controller: _petBio,
                  maxLength: 500,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Tell us more about your pet',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  ),
                  inputFormatters: [NewFormatter()],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText =
        newValue.text.replaceAll('\n', '').replaceAll(RegExp(r'\s+'), ' ');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
