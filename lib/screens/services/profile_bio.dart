import 'package:animalreconnect/screens/widgets/button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String userId;
  final String imageUrl;
  final String username;
  final String bio;
  final String email;
  final String gender;
  final bool showGender;

  UserProfile({
    required this.userId,
    required this.imageUrl,
    required this.username,
    required this.bio,
    required this.email,
    required this.gender,
    required this.showGender,
  });
}

class PetProfile {
  final String id;
  final String name;
  final String profileImageUrl;

  PetProfile(
      {required this.id, required this.name, required this.profileImageUrl});
}

class ProfileDetail extends StatefulWidget {
  final String userId;
  final String? petLikedId;

  const ProfileDetail({required this.userId, this.petLikedId, super.key});

  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> {
  late Future<UserProfile> userProfileFuture;
  late Future<List<PetProfile>> petsFuture;
  bool canAddMorePets = true;
  late String profileId;
  late String currentUserId;
  bool hasLikedCurrentUsersPet = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    profileId = widget.userId;
    userProfileFuture = fetchUserProfile(profileId);
    petsFuture = fetchPetProfile(profileId).then((pets) {
      setState(() {
        canAddMorePets = pets.length < 4;
      });
      return pets;
    });
    checkIfLikedCurrentUsersPet();
  }

  void updateProfile() {
    setState(() {
      userProfileFuture = fetchUserProfile(profileId);
      petsFuture = fetchPetProfile(profileId).then((pets) {
        setState(() {
          canAddMorePets = pets.length < 4;
        });
        return pets;
      });
    });
  }

  Future<UserProfile> fetchUserProfile(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();
    final prefs = await SharedPreferences.getInstance();
    bool showGender = prefs.getBool('showGender') ?? false;

    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      String imageUrl = data['imageUrl'] as String? ??
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png';
      String username = data['username'] as String? ?? 'Anonymous';
      String bio =
          data['profileDescription'] as String? ?? 'Pleased to meet you!';
      String email = data['email'] as String;
      String gender = data['gender'] as String? ?? 'Not specified';
      return UserProfile(
          userId: userId,
          imageUrl: imageUrl,
          username: username,
          bio: bio,
          email: email,
          gender: gender,
          showGender: showGender);
    } else {
      return UserProfile(
          userId: userId,
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png',
          username: 'Anonymous',
          bio: 'Pleased to meet you!',
          email: 'None',
          gender: 'Not specified',
          showGender: showGender);
    }
  }

  Future<List<PetProfile>> fetchPetProfile(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot petDocs = await firestore
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .get();

    if (petDocs.docs.isNotEmpty) {
      return petDocs.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return PetProfile(
            id: doc.id,
            name: data['name'],
            profileImageUrl: data['profileImageUrl']);
      }).toList();
    } else {
      return [];
    }
  }

  Future<void> checkIfLikedCurrentUsersPet() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    QuerySnapshot likedPetsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(profileId)
        .collection('interactions')
        .where('interaction', isEqualTo: 'liked')
        .get();

    if (likedPetsSnapshot.docs.isNotEmpty) {
      for (var doc in likedPetsSnapshot.docs) {
        DocumentSnapshot petDoc = await FirebaseFirestore.instance
            .collection('pets')
            .doc(doc['petId'])
            .get();
        if (petDoc.exists) {
          var petData = petDoc.data() as Map<String, dynamic>;
          if (petData['ownerId'] == currentUserId) {
            setState(() {
              hasLikedCurrentUsersPet = true;
            });
            break;
          }
        }
      }
    }
  }

  Future<void> acceptRequest() async {
    DocumentReference matchRef =
        await FirebaseFirestore.instance.collection('matches').add({
      'user1': currentUserId,
      'user2': profileId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    QuerySnapshot likedPetsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(profileId)
        .collection('interactions')
        .where('interaction', isEqualTo: 'liked')
        .get();

    for (var doc in likedPetsSnapshot.docs) {
      if (doc.exists) {
        var interactionData = doc.data() as Map<String, dynamic>;
        String petId = interactionData['petId'];

        DocumentSnapshot petDoc = await FirebaseFirestore.instance
            .collection('pets')
            .doc(petId)
            .get();

        if (petDoc.exists) {
          var petData = petDoc.data() as Map<String, dynamic>;
          if (petData['ownerId'] == currentUserId) {
            await doc.reference.update({'interaction': 'accepted'});
          }
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted')),
      );
      Navigator.pushNamed(context, '/showChat/',
          arguments: {'matchId': matchRef.id});
    }
  }

  Future<void> rejectRequest() async {
    bool? hideAllPets = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hide All Pets?'),
          content:
              const Text('Do you want to hide all your pets from this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (hideAllPets == null) {
      return;
    }
    QuerySnapshot likedPetsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(profileId)
        .collection('interactions')
        .where('interaction', isEqualTo: 'liked')
        .get();

    for (var doc in likedPetsSnapshot.docs) {
      if (doc.exists) {
        var interactionData = doc.data() as Map<String, dynamic>;
        String petId = interactionData['petId'];

        DocumentSnapshot petDoc = await FirebaseFirestore.instance
            .collection('pets')
            .doc(petId)
            .get();

        if (petDoc.exists && hideAllPets) {
          var petData = petDoc.data() as Map<String, dynamic>;
          if (petData['ownerId'] == currentUserId) {
            await doc.reference.update({'interaction': 'rejected'});
          }
        } else if (petDoc.exists && !hideAllPets) {
          var petData = petDoc.data() as Map<String, dynamic>;
          if (petData['ownerId'] == currentUserId &&
              petData['id'] == widget.petLikedId) {
            await doc.reference.update({'interaction': 'rejected'});
            break;
          }
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
      Navigator.pop(context, true);
    }

    setState(() {
      hasLikedCurrentUsersPet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Center(
              child: Column(
                children: [
                  FutureBuilder<UserProfile>(
                    future: userProfileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        bool isCurrentUserProfile =
                            snapshot.data!.userId == currentUserId;
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 64,
                              backgroundImage:
                                  NetworkImage(snapshot.data!.imageUrl),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              snapshot.data!.username,
                              style: GoogleFonts.inriaSans(
                                fontSize: screenHeight * 0.03,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: screenHeight * 0.2,
                                  maxHeight: screenHeight * 0.2,
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    snapshot.data!.bio,
                                    style: GoogleFonts.inriaSans(
                                        fontSize: screenHeight * 0.02),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (snapshot.data!.showGender)
                              Align(
                                alignment: Alignment.centerLeft,
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
                                      TextSpan(text: snapshot.data!.gender),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05),
                              child: Row(children: [
                                Text(
                                  'My Pets',
                                  style: GoogleFonts.inriaSans(
                                      fontSize: screenHeight * 0.025,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' (upto 4)',
                                  style: GoogleFonts.inriaSans(
                                      fontSize: screenHeight * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (isCurrentUserProfile && canAddMorePets)
                                  IconButton(
                                      onPressed: () {
                                        if (mounted) {
                                          Navigator.of(context).pushNamed(
                                            '/setUpPetProfile/',
                                            arguments: {
                                              'onProfileUpdated': updateProfile,
                                              'petData': null,
                                            },
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add))
                              ]),
                            ),
                            const SizedBox(height: 20),
                            FutureBuilder<List<PetProfile>>(
                                future: petsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    List<PetProfile> pets =
                                        snapshot.data!.take(4).toList();
                                    return Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: pets.map((pet) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              '/showPetProfile/',
                                              arguments: {
                                                'petId': pet.id,
                                                'onProfileUpdated':
                                                    updateProfile,
                                              },
                                            );
                                          },
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: screenWidth * 0.3,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    pet.profileImageUrl,
                                                    width: screenWidth * 0.3,
                                                    height: screenWidth * 0.3,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  pet.name,
                                                  style: GoogleFonts.inriaSans(
                                                    fontSize:
                                                        screenHeight * 0.02,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  } else {
                                    return const CircularProgressIndicator(
                                        color: Colors.grey);
                                  }
                                }),
                            const SizedBox(height: 50),
                            if (!isCurrentUserProfile &&
                                hasLikedCurrentUsersPet)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  createButton(
                                      screenWidth * 0.3, screenHeight * 0.06,
                                      () {
                                    acceptRequest();
                                  },
                                      'Accept',
                                      Colors.white,
                                      screenHeight * 0.0225,
                                      const Color.fromARGB(255, 247, 184, 1),
                                      const Color.fromARGB(255, 241, 132, 1),
                                      Colors.transparent,
                                      Colors.transparent),
                                  createButton(
                                      screenWidth * 0.3, screenHeight * 0.06,
                                      () {
                                    rejectRequest();
                                  },
                                      'Reject',
                                      Colors.white,
                                      screenHeight * 0.0225,
                                      const Color.fromARGB(255, 247, 184, 1),
                                      const Color.fromARGB(255, 241, 132, 1),
                                      Colors.transparent,
                                      Colors.transparent),
                                ],
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
