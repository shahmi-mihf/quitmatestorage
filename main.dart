import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quitemate/login.dart';
import 'package:quitemate/profile.dart';
import 'firebase_options.dart';
import 'package:quitemate/home.dart';
import 'package:quitemate/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: const Home(),
    routes: {
      '/register': (context) => const Register(),
      '/login': (context) => const Login(),
      '/profile': (context) => const Profile(),

    },
  ));
}