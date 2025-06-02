import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/register_page.dart';
import 'screens/reset_password_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_page.dart';
import 'admin_screens/admhome_page.dart';
import 'screens/guest_request_page.dart';
import 'screens/add_task_screen.dart';
import 'screens/organizer_home_screen.dart';
import 'screens/organizer_task_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VolunteerHelp',
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.teal[900],
          displayColor: Colors.teal[900],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[700],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: TextStyle(color: Colors.teal[800]),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home:
          FirebaseAuth.instance.currentUser == null
              ? const LoginPage()
              : const HomePage(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/reset': (context) => ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminHomePage(),
        '/login': (context) => LoginPage(),
        '/guestRequest': (context) => const GuestRequestPage(),
        '/organizerHome':
            (context) => OrganizerHomePage(
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
        '/addTask': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return AddTaskPage(userId: userId);
        },
        '/taskDetail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return OrganizerTaskDetailsPage(taskData: args);
        },
      },
    );
  }
}
