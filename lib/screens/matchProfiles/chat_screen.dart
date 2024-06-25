import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;

  const ChatScreen({required this.matchId, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late ChatUser currentUser;
  late ChatUser otherUser;
  late CollectionReference chatReference;
  String otherUserName = '';
  String otherUserId = '';
  String otherUserImageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchCurrentUserData();
    chatReference = _firestore
        .collection('matches')
        .doc(widget.matchId)
        .collection('messages');
    fetchOtherUserName();
  }

  Future<void> fetchCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          currentUser = ChatUser(
            id: user.uid,
            firstName: userData['username'] ?? 'User',
            profileImage: userData['imageUrl'] ?? '',
          );
        });
      }
    } catch (e) {
      print("Error fetching current user data: $e");
    }
  }

  Future<void> fetchOtherUserName() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot matchDoc =
          await _firestore.collection('matches').doc(widget.matchId).get();
      if (matchDoc.exists) {
        Map<String, dynamic> matchData =
            matchDoc.data() as Map<String, dynamic>;
        String user1Id = matchData['user1'] ?? '';
        String user2Id = matchData['user2'] ?? '';

        otherUserId = user1Id == user.uid ? user2Id : user1Id;

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            otherUserName = userData['username'] ?? 'User';
            otherUserImageUrl = userData['imageUrl'] ?? '';
            otherUser = ChatUser(
              id: otherUserId,
              firstName: otherUserName,
              profileImage: otherUserImageUrl,
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching other user name: $e");
    }
  }

  Future<String> uploadImageToFirebase(File image) async {
    String fileName = basename(image.path);
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('chats/${widget.matchId}/$fileName');
    UploadTask uploadTask = storageReference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void onSend(ChatMessage message) async {
    try {
      if (message.customProperties != null &&
          message.customProperties!['image'] != null) {
        String imageUrl =
            await uploadImageToFirebase(message.customProperties!['image']);
        message = ChatMessage(
          user: message.user,
          medias: [
            ChatMedia(
              url: imageUrl,
              fileName: basename(imageUrl),
              type: MediaType.image,
            ),
          ],
          text: message.text,
          createdAt: message.createdAt,
        );
      }
      await chatReference.add(message.toJson());
      await _firestore.collection('matches').doc(widget.matchId).update({
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error sending message: $e");
    }
  }

  Future<void> selectImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      ChatMessage imageMessage = ChatMessage(
        user: currentUser,
        customProperties: {'image': image},
        createdAt: DateTime.now(),
      );
      onSend(imageMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUserName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/homepage/',
              (route) => false,
              arguments: {'initialTabIndex': 3},
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            chatReference.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          try {
            List<ChatMessage> messages = snapshot.data!.docs.map((doc) {
              return ChatMessage.fromJson(doc.data() as Map<String, dynamic>);
            }).toList();

            return DashChat(
              currentUser: currentUser,
              onSend: onSend,
              messages: messages,
              inputOptions: InputOptions(
                sendOnEnter: true,
                inputDecoration:
                    const InputDecoration(hintText: 'Type a message...'),
                inputToolbarPadding: const EdgeInsets.all(8.0),
                leading: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: selectImage,
                  ),
                  
                ],
              ),
            );
          } catch (e) {
            // ignore: avoid_print
            print("Error displaying messages: $e");
            return const Center(child: Text('Error displaying messages'));
          }
        },
      ),
    );
  }
}
