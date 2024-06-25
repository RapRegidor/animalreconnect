import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({
    super.key,
  });

  @override
  MessagingScreenState createState() => MessagingScreenState();
}

class MessagingScreenState extends State<MessagingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void refreshTabs() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Requests'),
            ],
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatsTab(onRefresh: refreshTabs),
          RequestsTab(onRefresh: refreshTabs),
        ],
      ),
    );
  }
}

class ChatsTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const ChatsTab({super.key, required this.onRefresh});

  Future<List<DocumentSnapshot>> fetchConversations() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      QuerySnapshot user1Matches = await FirebaseFirestore.instance
          .collection('matches')
          .where('user1', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      QuerySnapshot user2Matches = await FirebaseFirestore.instance
          .collection('matches')
          .where('user2', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<DocumentSnapshot> matches = [];
      matches.addAll(user1Matches.docs);
      matches.addAll(user2Matches.docs);
      matches.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      return matches;
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching conversations: $e");
      throw Exception('Error fetching conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: fetchConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading conversations'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No conversations available'));
        } else {
          List<DocumentSnapshot> matches = snapshot.data!;
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              var match = matches[index].data() as Map<String, dynamic>;
              String matchId = matches[index].id;
              String otherUserId =
                  (match['user1'] == FirebaseAuth.instance.currentUser!.uid)
                      ? match['user2']
                      : match['user1'];
              Timestamp lastUpdated = match['timestamp'] ?? Timestamp.now();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Error loading user data'),
                    );
                  } else {
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    String formattedDate = DateFormat('MMM dd, yyyy hh:mm a')
                        .format(lastUpdated.toDate());

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/showUserProfile/',
                            arguments: {
                              'userId': otherUserId,
                            },
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(userData['imageUrl'] ??
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png'),
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/showChat/',
                            arguments: {
                              'matchId': matchId,
                            },
                          ).then((_) => onRefresh());
                        },
                        child: Text(userData['username'] ?? 'User'),
                      ),
                      subtitle: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/showChat/',
                            arguments: {
                              'matchId': matchId,
                            },
                          ).then((_) => onRefresh());
                        },
                        child: Text('Last updated: $formattedDate'),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/showChat/',
                          arguments: {
                            'matchId': matchId,
                          },
                        ).then((_) => onRefresh());
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}

class RequestsTab extends StatefulWidget {
  final VoidCallback onRefresh;

  const RequestsTab({super.key, required this.onRefresh});

  @override
  RequestsTabState createState() => RequestsTabState();
}

class RequestsTabState extends State<RequestsTab>
    with SingleTickerProviderStateMixin {
  late TabController _nestedTabController;

  @override
  void initState() {
    super.initState();
    _nestedTabController = TabController(length: 2, vsync: this);
    markAllRequestsAsRead();
  }

  Future<void> markAllRequestsAsRead() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collectionGroup('interactions')
        .where('ownerId', isEqualTo: user.uid)
        .where('interaction', isEqualTo: 'liked')
        .where('isNew', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isNew': false});
    }
  }

  @override
  void dispose() {
    _nestedTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: TabBar(
            controller: _nestedTabController,
            tabs: const [
              Tab(text: 'Sent'),
              Tab(text: 'Received'),
            ],
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _nestedTabController,
            children: [
              SentRequestsTab(onRefresh: widget.onRefresh),
              ReceivedRequestsTab(onRefresh: widget.onRefresh),
            ],
          ),
        ),
      ],
    );
  }
}

class SentRequestsTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const SentRequestsTab({super.key, required this.onRefresh});

  Future<List<Map<String, dynamic>>> fetchSentRequests() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('interactions')
        .where('interaction', isEqualTo: 'liked')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['petId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> deleteRequest(String petId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('interactions')
        .doc(petId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchSentRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading sent requests'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sent requests'));
        } else {
          List<Map<String, dynamic>> sentRequests = snapshot.data!;
          return ListView.builder(
            itemCount: sentRequests.length,
            itemBuilder: (context, index) {
              var request = sentRequests[index];
              return Dismissible(
                key: Key(request['petId']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  deleteRequest(request['petId']);
                  sentRequests.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request deleted')),
                  );
                  onRefresh();
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('pets')
                      .doc(request['petId'])
                      .get(),
                  builder: (context, petSnapshot) {
                    if (petSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    } else if (petSnapshot.hasError || !petSnapshot.hasData) {
                      return const ListTile(
                        title: Text('Error loading pet data'),
                      );
                    } else {
                      var petData =
                          petSnapshot.data!.data() as Map<String, dynamic>;
                      DateTime timestamp = request['timestamp'].toDate();
                      String formattedDate =
                          DateFormat('MMM dd yyyy, h:mm a').format(timestamp);
                      return ListTile(
                        leading: Image.network(
                          petData['profileImageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(petData['name']),
                        subtitle: Text('Timestamp: $formattedDate'),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/showPetProfile/',
                            arguments: {
                              'petId': request['petId'],
                              'onProfileUpdated': () => onRefresh(),
                            },
                          ).then((_) => onRefresh());
                        },
                      );
                    }
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}

class ReceivedRequestsTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const ReceivedRequestsTab({super.key, required this.onRefresh});

  Future<List<Map<String, dynamic>>> fetchReceivedRequests() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Fetch pets owned by the current user
      QuerySnapshot petSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      if (petSnapshot.docs.isEmpty) {
        return [];
      }

      List<String> petIds = petSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch interactions in descending order by timestamp
      QuerySnapshot interactionSnapshot = await FirebaseFirestore.instance
          .collectionGroup('interactions')
          .where('interaction', isEqualTo: 'liked')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> receivedRequests = interactionSnapshot.docs
          .where((doc) => petIds.contains(doc.id))
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['petId'] = doc.id;
        data['userId'] = doc.reference.parent.parent!.id;
        data['interactionDocId'] = doc.id;
        return data;
      }).toList();

      return receivedRequests;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching received requests: $e');
      throw Exception('Error fetching received requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchReceivedRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading received requests'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No received requests'));
        } else {
          List<Map<String, dynamic>> receivedRequests = snapshot.data!;
          return ListView.builder(
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              var request = receivedRequests[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('pets')
                    .doc(request['petId'])
                    .get(),
                builder: (context, petSnapshot) {
                  if (petSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  } else if (petSnapshot.hasError || !petSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Error loading pet data'),
                    );
                  } else {
                    var petData =
                        petSnapshot.data!.data() as Map<String, dynamic>;
                    DateTime timestamp = request['timestamp'].toDate();
                    String formattedDate =
                        DateFormat('MMM dd yyyy, h:mm a').format(timestamp);
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(request['userId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        } else if (userSnapshot.hasError ||
                            !userSnapshot.hasData) {
                          return const ListTile(
                            title: Text('Error loading user data'),
                          );
                        } else {
                          var userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: Image.network(
                              petData['profileImageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text('Liked by: ${userData['username']}'),
                            subtitle: Text(
                              'Timestamp: $formattedDate',
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/showUserProfile/',
                                arguments: {
                                  'userId': request['userId'],
                                  'petLikedId': petData['id'],
                                },
                              ).then((_) => onRefresh());
                            },
                          );
                        }
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}
