import 'package:animalreconnect/firebase_options.dart';
import 'package:animalreconnect/screens/auth/account_reg.dart';
import 'package:animalreconnect/screens/auth/forgot_password.dart';
import 'package:animalreconnect/screens/auth/verification_code.dart';
import 'package:animalreconnect/screens/matchProfiles/chat_screen.dart';
import 'package:animalreconnect/screens/petProfile/add_pet.dart';
import 'package:animalreconnect/screens/petProfile/filter.dart';
import 'package:animalreconnect/screens/petProfile/pet_profile.dart';
import 'package:animalreconnect/screens/profileSetup/edit_profile.dart';
import 'package:animalreconnect/screens/profileSetup/profile_picture.dart';
import 'package:animalreconnect/screens/profileSetup/user_profile.dart';
import 'package:animalreconnect/screens/services/faq.dart';
import 'package:animalreconnect/screens/services/favorites.dart';
import 'package:animalreconnect/screens/services/nav_bar.dart';
import 'package:animalreconnect/screens/profileSetup/birth_date.dart';
import 'package:animalreconnect/screens/profileSetup/first_name.dart';
import 'package:animalreconnect/screens/profileSetup/gender.dart';
import 'package:animalreconnect/screens/profileSetup/username.dart';
import 'package:animalreconnect/screens/profileSetup/welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const MyWidget(),
    routes: {
      '/login/': (context) => const LoginPage(),
      '/register/': (context) => const SignUp(),
      '/resetPassword/': (context) => const ResetPassword(),
      '/verifyEmail/': (context) => const VerificationEmail(),
      '/welcome/': (context) => const Welcome(),
      '/homepage/': (context) => UserProfile(
            initialTabIndex: (ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?)?['initialTabIndex'] ??
                0,
          ),
      '/setUpFirstName/': (context) => const FirstName(),
      '/setUpProfilePicture/': (context) => const ProfilePicture(),
      '/showFAQ/': (context) => const ShowFAQ(),
      '/showFavorites/': (context) => const Favorites(),
      '/filterPets/': (context) => const FilterPets(),
    },
    onGenerateRoute: (settings) {
      if (settings.name == '/setUpPetProfile/') {
        final args = settings.arguments as Map<String, dynamic>;
        final VoidCallback onProfileUpdated = args['onProfileUpdated'];
        final Map<String, dynamic>? petData = args['petData'];
        return MaterialPageRoute(
          builder: (context) {
            return CreatePetProfile(
              onProfileUpdated: onProfileUpdated,
              petData: petData,
            );
          },
        );
      } else if (settings.name == '/showPetProfile/') {
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        final String petId = args['petId'] as String;
        final VoidCallback onProfileUpdated = args['onProfileUpdated'];
        return MaterialPageRoute(
          builder: (context) {
            return PetProfileDisplay(
                petId: petId, onProfileUpdated: onProfileUpdated);
          },
        );
      } else if (settings.name == '/editUserProfile/') {
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        final String userId = args['userId'] as String;
        return MaterialPageRoute(
          builder: (context) {
            return EditUserProfile(
              userId: userId,
            );
          },
        );
      } else if (settings.name == '/showUserProfile/') {
        final args = settings.arguments as Map<String, dynamic>;
        final String userId = args['userId'];

        return MaterialPageRoute(
          builder: (context) {
            return UserProfileScreen(userId: userId);
          },
        );
      } else if (settings.name == '/showChat/') {
        final args = settings.arguments as Map<String, dynamic>;
        final String matchId = args['matchId'];
        return MaterialPageRoute(
          builder: (context) {
            return ChatScreen(matchId: matchId);
          },
        );
      } else if (settings.name == '/setUpUsername/') {
        final args = settings.arguments as Map<String, dynamic>;
        final bool isEditMode = args['isEditMode'];
        final String currentUsername = args['currentUsername'];
        return MaterialPageRoute(
          builder: (context) {
            return Username(
                isEditMode: isEditMode, currentUsername: currentUsername);
          },
        );
      } else if (settings.name == '/setUpGender/') {
        final args = settings.arguments as Map<String, dynamic>;
        final bool isEditMode = args['isEditMode'];
        final String currentGender = args['currentGender'];
        return MaterialPageRoute(
          builder: (context) {
            return Gender(isEditMode: isEditMode, currentGender: currentGender);
          },
        );
      } else if (settings.name == '/setUpBirthDate/') {
        final args = settings.arguments as Map<String, dynamic>;
        final bool isEditMode = args['isEditMode'];

        return MaterialPageRoute(
          builder: (context) {
            return BirthDate(isEditMode: isEditMode);
          },
        );
      }

      return null;
    },
  ));
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  Future<String> initializeFirebaseAndCheckUser() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '/login/';
    } else {
      return '/verifyEmail/';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: initializeFirebaseAndCheckUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              Future.microtask(() =>
                  Navigator.of(context).pushReplacementNamed(snapshot.data!));
              return const SizedBox();
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
