import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/helpers.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = authResult.user!.uid;

      // Проверяем роль в коллекции users
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String? role = userDoc.data()?['role'];

      // Если роль не найдена в users — попробуем в guests
      if (role == null) {
        final guestDoc = await FirebaseFirestore.instance.collection('guests').doc(uid).get();
        if (guestDoc.exists) {
          role = 'guest';
        }
      }

      if (role == null) {
        role = 'user'; // По умолчанию обычный пользователь
      }

      showSuccess("Успешный вход!");

      Future.delayed(const Duration(milliseconds: 500), () {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'guest') {
          Navigator.pushReplacementNamed(context, '/guestHome');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Ошибка входа");
    } catch (e) {
      showError("Ошибка при получении роли");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Пароль")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Войти")),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Нет аккаунта? Зарегистрироваться"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/reset'),
              child: const Text("Забыли пароль?"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/guestRequest');
              },
              child: const Text("Оставить заявку"),
            ),
          ],
        ),
      ),
    );
  }
}
