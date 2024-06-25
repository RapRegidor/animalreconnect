import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PetProfileDisplay extends StatefulWidget {
  final String petId;
  final VoidCallback onProfileUpdated;
  const PetProfileDisplay(
      {super.key, required this.petId, required this.onProfileUpdated});

  @override
  State<PetProfileDisplay> createState() => _PetProfileDisplayState();
}

class _PetProfileDisplayState extends State<PetProfileDisplay> {
  late Future<Map<String, dynamic>?> petProfileFuture;
  final FirebaseAuth currentInstance = FirebaseAuth.instance;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    petProfileFuture = fetchPetProfile(widget.petId);
    checkIfFavorite();
  }

  Future<Map<String, dynamic>?> fetchPetProfile(String petId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot petDoc =
        await firestore.collection('pets').doc(petId).get();

    if (petDoc.exists && petDoc.data() != null) {
      return petDoc.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  Future<void> checkIfFavorite() async {
    User? user = currentInstance.currentUser;
    if (user == null) return;

    DocumentSnapshot favoriteDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.petId)
        .get();

    setState(() {
      isFavorite = favoriteDoc.exists;
    });
  }

  void deletePetProfile() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot petDoc =
        await firestore.collection('pets').doc(widget.petId).get();

    if (petDoc.exists && petDoc.data() != null) {
      var petData = petDoc.data() as Map<String, dynamic>;
      List<String> galleryImageUrls =
          List<String>.from(petData['galleryImageUrls'] ?? []);

      await deleteImagesFromStorage(galleryImageUrls);

      await firestore.collection('pets').doc(widget.petId).delete();
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
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    }
  }

  void reportPetProfile(String reason) async {
    User? currentUser = currentInstance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('reports').add({
      'petId': widget.petId,
      'reporterId': currentUser.uid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reported for $reason')),
      );
    }
  }

  void showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Report Pet Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Scam"),
                onTap: () {
                  Navigator.of(context).pop();
                  reportPetProfile("Scam");
                },
              ),
              ListTile(
                title: const Text("Duplicate Pets"),
                onTap: () {
                  Navigator.of(context).pop();
                  reportPetProfile("Duplicate Pets");
                },
              ),
              ListTile(
                title: const Text("Breeder"),
                onTap: () {
                  Navigator.of(context).pop();
                  reportPetProfile("Breeder");
                },
              ),
              ListTile(
                title: const Text("Others"),
                onTap: () {
                  Navigator.of(context).pop();
                  reportPetProfile("Others");
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleUnfavorite() async {
    User? user = currentInstance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.petId)
        .delete();

    setState(() {
      isFavorite = false;
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void handleSwipe(bool liked) async {
    User? user = currentInstance.currentUser;
    if (user == null) return;

    String interactionType = liked ? 'liked' : 'disliked';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('interactions')
        .doc(widget.petId)
        .set({
      'petId': widget.petId,
      'interaction': interactionType,
      'timestamp': FieldValue.serverTimestamp(),
      'isNew': true,
    });

    if (liked) {
      DocumentSnapshot petOwnerDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .get();
      if (petOwnerDoc.exists) {
        String ownerId = petOwnerDoc['ownerId'];
        DocumentSnapshot ownerInteractionsDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .collection('interactions')
            .doc(user.uid)
            .get();

        if (ownerInteractionsDoc.exists &&
            ownerInteractionsDoc['interaction'] == 'liked') {
          await FirebaseFirestore.instance.collection('matches').add({
            'user1': user.uid,
            'user2': ownerId,
            'petId': widget.petId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    handleUnfavorite();
  }

  Future<String?> fetchProfileName(String petId) async {
    DocumentSnapshot petOwnerDoc = await FirebaseFirestore.instance
        .collection('pets')
        .doc(widget.petId)
        .get();
    String ownerId = petOwnerDoc['ownerId'];
    DocumentSnapshot ownerDoc =
        await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    return ownerDoc['username'];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    User? currentUser = currentInstance.currentUser;

    return FutureBuilder<Map<String, dynamic>?>(
      future: petProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading pet profile.'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Pet profile not found.'));
        } else {
          var petData = snapshot.data!;
          List<String> allImageUrls =
              List<String>.from(petData['galleryImageUrls']);
          bool isOwner =
              currentUser != null && petData['ownerId'] == currentUser.uid;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isOwner && isFavorite)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up),
                          color: Colors.green,
                          onPressed: () {
                            handleSwipe(true);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down),
                          color: Colors.red,
                          onPressed: () {
                            handleSwipe(false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite),
                          color: Colors.blue,
                          onPressed: handleUnfavorite,
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.of(context).pushNamed(
                        '/setUpPetProfile/',
                        arguments: {
                          'onProfileUpdated': widget.onProfileUpdated,
                          'petData': petData,
                        },
                      );

                      if (result == true) {
                        setState(() {
                          petProfileFuture = fetchPetProfile(widget.petId);
                        });
                      }
                    },
                  ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text(
                                "Are you sure you want to delete this pet profile?"),
                            actions: [
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text("Delete"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  deletePetProfile();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                if (!isOwner)
                  IconButton(
                    icon: const Icon(Icons.report),
                    onPressed: showReportDialog,
                  ),
              ],
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.orange.withOpacity(0.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${petData['name']} (${petData['gender']})',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: [
                                  if (petData['age'] != null &&
                                      petData['age'] > 0)
                                    Chip(
                                      label: Text('${petData['age']} year(s)'),
                                    ),
                                  Chip(
                                    label: Text(petData['species']),
                                  ),
                                  if (petData['weight'] != null &&
                                      petData['weight'] > 0)
                                    Chip(
                                      label: Text('${petData['weight']} lbs'),
                                    ),
                                  Chip(
                                    label: Text(
                                        'Care level ${petData['careLevel']}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 20),
                                  const SizedBox(width: 4),
                                  Text('Location: ${petData['location']}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(petData['bio']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: allImageUrls
                          .map<Widget>((url) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: (screenWidth - 40) / 2,
                                  height: (screenWidth - 40) / 2,
                                  fit: BoxFit.cover,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
