import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';
import 'screens/initial_profile_setup_screen.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageService(),
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'Gym Leveling',
            theme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            locale: languageService.currentLocale,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  final User? user = snapshot.data;
                  if (user != null) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                      builder: (context, userDocSnapshot) {
                        if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                          final userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
                          if (userData['isProfileSetupComplete'] == true) {
                            return const HomeScreen();
                          } else {
                            return const InitialProfileSetupScreen();
                          }
                        } else {
                          return const InitialProfileSetupScreen();
                        }
                      },
                    );
                  }
                }
                return const LoginScreen();
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}