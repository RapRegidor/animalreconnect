import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PetSwipe extends StatefulWidget {
  final Map<String, bool> filters;
  final void Function(Map<String, bool>) onFiltersUpdated;

  const PetSwipe(
      {super.key, required this.filters, required this.onFiltersUpdated});

  @override
  State<PetSwipe> createState() => _PetSwipeState();
}

class _PetSwipeState extends State<PetSwipe> {
  late Future<List<Map<String, dynamic>>> petsFuture;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CardSwiperController _swiperController = CardSwiperController();
  String? firstPetId;

  @override
  void initState() {
    super.initState();
    petsFuture = loadFirstPetId();
  }

  Future<void> saveFirstPetId(String petId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstPetId', petId);
  }

  Future<List<Map<String, dynamic>>> loadFirstPetId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    firstPetId = prefs.getString('firstPetId');
    return fetchPets();
  }

  Future<List<Map<String, dynamic>>> fetchPets() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Fetch matches
    QuerySnapshot matchesSnapshot = await _firestore
        .collection('matches')
        .where('user1', isEqualTo: user.uid)
        .get();
    List<String> matchedUserIds = matchesSnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['user2'] as String)
        .toList();

    matchesSnapshot = await _firestore
        .collection('matches')
        .where('user2', isEqualTo: user.uid)
        .get();
    matchedUserIds.addAll(matchesSnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['user1'] as String)
        .toList());

    // Fetch interactions
    QuerySnapshot interactionsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interactions')
        .get();
    List<String> interactedPetIds =
        interactionsSnapshot.docs.map((doc) => doc.id).toList();

    QuerySnapshot favoritesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    List<String> favoritePetIds =
        favoritesSnapshot.docs.map((doc) => doc.id).toList();

    List<String> excludedPetIds = [...interactedPetIds, ...favoritePetIds];

    // Fetch pets
    QuerySnapshot petsSnapshot = await _firestore.collection('pets').get();
    List<Map<String, dynamic>> pets = [];
    for (var doc in petsSnapshot.docs) {
      Map<String, dynamic>? petData = doc.data() as Map<String, dynamic>?;
      if (petData != null &&
          !excludedPetIds.contains(doc.id) &&
          !matchedUserIds.contains(petData['ownerId']) &&
          petData['ownerId'] != user.uid) {
        pets.add(petData);
      }
    }

    // Apply filters
    pets = pets.where((pet) {
      // Filter by species
      bool speciesMatch = true;
      if (widget.filters['dogSelected']! ||
          widget.filters['catSelected']! ||
          widget.filters['otherSelected']!) {
        speciesMatch = false;
        if (widget.filters['dogSelected']! && pet['species'] == 'Dog') {
          speciesMatch = true;
        }
        if (widget.filters['catSelected']! && pet['species'] == 'Cat') {
          speciesMatch = true;
        }
        if (widget.filters['otherSelected']! && pet['species'] == 'Others') {
          speciesMatch = true;
        }
      }

      // Filter by age
      bool ageMatch = true;
      if (widget.filters['babySelected']! ||
          widget.filters['youngSelected']! ||
          widget.filters['oldSelected']! ||
          widget.filters['anyAgeSelected']!) {
        ageMatch = false;
        if (widget.filters['babySelected']! && pet['age'] <= 1) {
          ageMatch = true;
        }
        if (widget.filters['youngSelected']! &&
            pet['age'] > 1 &&
            pet['age'] <= 5) {
          ageMatch = true;
        }
        if (widget.filters['oldSelected']! && pet['age'] > 5) {
          ageMatch = true;
        }
        if (widget.filters['anyAgeSelected']! && pet['age'] >= 0) {
          ageMatch = true;
        }
      }

      // Filter by care level
      bool careLevelMatch = true;
      if (widget.filters['basicCareSelected']! ||
          widget.filters['standardCareSelected']! ||
          widget.filters['moderateCareSelected']! ||
          widget.filters['advancedCareSelected']! ||
          widget.filters['specializedCareSelected']!) {
        careLevelMatch = false;
        if (widget.filters['basicCareSelected']! &&
            pet['careLevel'] == '1 - Basic Care') {
          careLevelMatch = true;
        }
        if (widget.filters['standardCareSelected']! &&
            pet['careLevel'] == '2 - Standard Care') {
          careLevelMatch = true;
        }
        if (widget.filters['moderateCareSelected']! &&
            pet['careLevel'] == '3 - Moderate Care') {
          careLevelMatch = true;
        }
        if (widget.filters['advancedCareSelected']! &&
            pet['careLevel'] == '4 - Advanced Care') {
          careLevelMatch = true;
        }
        if (widget.filters['specializedCareSelected']! &&
            pet['careLevel'] == '5 - Specialized Care') {
          careLevelMatch = true;
        }
      }

      return speciesMatch && ageMatch && careLevelMatch;
    }).toList();

    pets.shuffle(Random());

    // Ensure the first pet is always the same until an action happens
    if (firstPetId != null) {
      int index = pets.indexWhere((pet) => pet['id'] == firstPetId);
      if (index != -1) {
        Map<String, dynamic> firstPet = pets.removeAt(index);
        pets.insert(0, firstPet);
      }
    } else if (pets.isNotEmpty) {
      firstPetId = pets[0]['id'];
      saveFirstPetId(firstPetId!);
    }

    return pets;
  }

  void handleSwipe(int index, bool liked, String petId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String interactionType = liked ? 'liked' : 'disliked';
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interactions')
        .doc(petId)
        .set({
      'petId': petId,
      'interaction': interactionType,
      'timestamp': FieldValue.serverTimestamp(),
      'isNew': true,
    });

    if (index == 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('firstPetId');
      List<Map<String, dynamic>> pets = await petsFuture;
      if (pets.length > 1) {
        await saveFirstPetId(pets[1]['id']);
      }
    }
  }

  void handleFavorite(int index, String petId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(petId)
        .set({
      'petId': petId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _swiperController.swipe(CardSwiperDirection.top);

    if (index == 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('firstPetId');
      List<Map<String, dynamic>> pets = await petsFuture;
      if (pets.length > 1) {
        await saveFirstPetId(pets[1]['id']);
      }
    }
  }

  @override
  void didUpdateWidget(PetSwipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters != oldWidget.filters) {
      setState(() {
        petsFuture = fetchPets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        children: [
          Image.asset('lib/images/animalReconnect_logo.png',
              height: screenHeight * 0.09),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: petsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading pets'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Sorry but no pets are available'));
                } else {
                  List<Map<String, dynamic>> pets = snapshot.data!;

                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          child: CardSwiper(
                            controller: _swiperController,
                            cardsCount: pets.length,
                            numberOfCardsDisplayed: 1,
                            onSwipe: (previousIndex, currentIndex, direction) {
                              if (direction == CardSwiperDirection.left) {
                                handleSwipe(previousIndex, false,
                                    pets[previousIndex]['id']);
                              } else if (direction ==
                                  CardSwiperDirection.right) {
                                handleSwipe(previousIndex, true,
                                    pets[previousIndex]['id']);
                              }
                              return true;
                            },
                            isLoop: false,
                            maxAngle: 10,
                            onEnd: () => {
                              setState(() {
                                petsFuture = Future.value([]);
                              })
                            },
                            threshold: 100,
                            allowedSwipeDirection:
                                const AllowedSwipeDirection.only(
                                    left: true, right: true),
                            padding: const EdgeInsets.all(0),
                            cardBuilder: (context,
                                index,
                                horizontalThresholdPercentage,
                                verticalThresholdPercentage) {
                              Map<String, dynamic> pet = pets[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        pet['profileImageUrl'],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: progress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? progress
                                                          .cumulativeBytesLoaded /
                                                      (progress
                                                              .expectedTotalBytes ??
                                                          1)
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16.0),
                                            bottomRight: Radius.circular(16.0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  pet['name'],
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.info,
                                                      size: 32),
                                                  color: Colors.white,
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                      '/showPetProfile/',
                                                      arguments: {
                                                        'petId': pet['id'],
                                                        'onProfileUpdated':
                                                            () => {},
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 20,
                                                    color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Located: ${pet['location']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.thumb_down,
                                                      size: 32),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    handleSwipe(index, false,
                                                        pet['id']);
                                                    _swiperController.swipe(
                                                        CardSwiperDirection
                                                            .left);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.favorite,
                                                      size: 32),
                                                  color: Colors.green,
                                                  onPressed: () {
                                                    handleFavorite(
                                                        index, pet['id']);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.thumb_up,
                                                      size: 32),
                                                  color: Colors.blue,
                                                  onPressed: () {
                                                    handleSwipe(
                                                        index, true, pet['id']);
                                                    _swiperController.swipe(
                                                        CardSwiperDirection
                                                            .right);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
