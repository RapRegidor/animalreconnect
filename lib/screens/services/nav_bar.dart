import 'package:animalreconnect/screens/auth/account_reg.dart';
import 'package:animalreconnect/screens/services/chat.dart';
import 'package:animalreconnect/screens/services/faq.dart';
import 'package:animalreconnect/screens/services/favorites.dart';
import 'package:animalreconnect/screens/services/match.dart';
import 'package:animalreconnect/screens/services/profile_bio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderProfile {
  final String imageUrl;
  final String username;

  HeaderProfile({required this.imageUrl, required this.username});
}

class UserProfile extends StatefulWidget {
  final int initialTabIndex;

  const UserProfile({super.key, this.initialTabIndex = 0});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  int _selectedIndex = 0;
  late Future<HeaderProfile> userProfileFuture;
  Map<String, bool> filters = {
    'dogSelected': false,
    'catSelected': false,
    'otherSelected': false,
    'babySelected': false,
    'youngSelected': false,
    'oldSelected': false,
    'anyAgeSelected': false,
    'basicCareSelected': false,
    'standardCareSelected': false,
    'moderateCareSelected': false,
    'advancedCareSelected': false,
    'specializedCareSelected': false,
  };

  void updateFilters(Map<String, bool> newFilters) {
    setState(() {
      filters = newFilters;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    userProfileFuture = fetchUserProfile(userId);
  }

  Future<HeaderProfile> fetchUserProfile(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      String imageUrl = data['imageUrl'] as String? ??
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png';
      String username = data['username'] as String? ?? 'Anonymous';
      return HeaderProfile(imageUrl: imageUrl, username: username);
    } else {
      return HeaderProfile(
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Default_pfp.svg/2048px-Default_pfp.svg.png',
          username: 'Anonymous');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    List<Widget> widgetOptions = [
      PetSwipe(
        filters: filters,
        onFiltersUpdated: updateFilters,
      ),
      const ShowFAQ(),
      const Favorites(),
      const MessagingScreen(),
      ProfileDetail(userId: userId),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _selectedIndex == 1
            ? Text(
                'Help Desk',
                style: GoogleFonts.inriaSans(fontWeight: FontWeight.bold),
              )
            : _selectedIndex == 2
                ? Text(
                    'Favorites',
                    style: GoogleFonts.inriaSans(fontWeight: FontWeight.bold),
                  )
                : _selectedIndex == 3
                    ? Text(
                        'Interactions',
                        style:
                            GoogleFonts.inriaSans(fontWeight: FontWeight.bold),
                      )
                    : null,
        centerTitle: true,
        actions: _selectedIndex == 4
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    if (mounted) {
                      Navigator.of(context)
                          .pushNamed('/editUserProfile/', arguments: {
                        'userId': userId,
                        'onUpdate': () => setState(() {
                              userProfileFuture = fetchUserProfile(userId);
                            })
                      });

      
                    }
                  },
                ),
              ]
            : _selectedIndex == 0
                ? [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () async {
                        final result = await Navigator.of(context)
                            .pushNamed('/filterPets/', arguments: filters);
                        if (result != null && result is Map<String, bool>) {
                          setState(() {
                            filters = result;
                          });
                        }
                      },
                    ),
                  ]
                : null,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: FutureBuilder<HeaderProfile>(
                  future: userProfileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Row(children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage:
                              NetworkImage(snapshot.data!.imageUrl),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          snapshot.data!.username,
                          style: GoogleFonts.inriaSans(
                            fontSize: screenHeight * 0.02,
                          ),
                        ),
                      ]);
                    } else {
                      return const CircularProgressIndicator(
                          color: Colors.grey);
                    }
                  }),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                onItemTapped(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login/', (_) => false);
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 4
          ? CustomPaint(
              painter: OrangePainter(),
              child: Center(
                child: widgetOptions.elementAt(_selectedIndex),
              ),
            )
          : Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
