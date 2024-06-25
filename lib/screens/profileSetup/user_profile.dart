import 'package:animalreconnect/screens/services/profile_bio.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen(
      {required this.userId,  super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ProfileDetail(userId: userId),
    );
  }
}
