import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/register_page.dart';
import 'screens/reset_password_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_page.dart';
import 'admin_screens/admhome_page.dart';
import 'screens/guest_request_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolunteerHelp',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : const HomePage(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/reset': (context) => ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminHomePage(),
        '/guestRequest': (context) => const GuestRequestPage(),
      },
    );
  }
}
