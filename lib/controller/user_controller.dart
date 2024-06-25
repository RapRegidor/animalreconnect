import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserController {
  static Future<User?> loginWithGoogle() async {
    final googleAccount = await GoogleSignIn().signIn();
    if (googleAccount == null) {
      return null;
    }
    final googleAuth = await googleAccount.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // If the user document does not exist, create it
        await userDoc.set({
          'email': user.email,
        });
      }
    }

    return user;
  }
}
