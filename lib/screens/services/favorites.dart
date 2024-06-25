import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  late Future<List<Map<String, dynamic>>> favoritesFuture;
  final FirebaseAuth instance = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    favoritesFuture = fetchFavorites();
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    User? user = instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Fetch the user's favorites
    QuerySnapshot favoritesSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    List<Map<String, dynamic>> favorites = [];
    for (var doc in favoritesSnapshot.docs) {
      DocumentSnapshot petSnapshot =
          await firestore.collection('pets').doc(doc.id).get();
      if (petSnapshot.exists) {
        favorites.add(petSnapshot.data() as Map<String, dynamic>);
      }
    }

    return favorites;
  }

  void updateFavorites() {
    setState(() {
      favoritesFuture = fetchFavorites();
    });
  }

  void handleUnfavorite(String petId) async {
    User? user = instance.currentUser;
    if (user == null) return;

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(petId)
        .delete();

    updateFavorites();
  }

  void handleSwipe(bool liked, String petId) async {
    User? user = instance.currentUser;
    if (user == null) return;

    String interactionType = liked ? 'liked' : 'disliked';
    await firestore
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

    if (liked) {
      DocumentSnapshot petOwnerDoc =
          await firestore.collection('pets').doc(petId).get();
      if (petOwnerDoc.exists) {
        String ownerId = petOwnerDoc['ownerId'];
        DocumentSnapshot ownerInteractionsDoc = await firestore
            .collection('users')
            .doc(ownerId)
            .collection('interactions')
            .doc(user.uid)
            .get();

        if (ownerInteractionsDoc.exists &&
            ownerInteractionsDoc['interaction'] == 'liked') {
          await firestore.collection('matches').add({
            'user1': user.uid,
            'user2': ownerId,
            'petId': petId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    handleUnfavorite(petId);
  }

  void showOptions(BuildContext context, String petId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.thumb_up),
                title: const Text('Like'),
                onTap: () {
                  handleSwipe(true, petId);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.thumb_down),
                title: const Text('Dislike'),
                onTap: () {
                  handleSwipe(false, petId);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Unfavorite'),
                onTap: () {
                  handleUnfavorite(petId);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorites'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorites available'));
          } else {
            List<Map<String, dynamic>> favorites = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio:
                    (screenWidth / 2 - 16) / ((screenWidth / 2 - 16) + 40),
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> pet = favorites[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.of(context).pushNamed(
                          '/showPetProfile/',
                          arguments: {
                            'petId': pet['id'],
                            'onProfileUpdated': updateFavorites,
                          },
                        );

                        if (result == true) {
                          updateFavorites();
                        }
                      },
                      child: GridTile(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                pet['profileImageUrl'],
                                width: screenWidth / 2 - 16,
                                height: screenWidth / 2 - 16,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              pet['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showOptions(context, pet['id']);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
