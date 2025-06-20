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
  bool _isLoading = false;

  void login() async {
    setState(() => _isLoading = true);
    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = authResult.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String? role = userDoc.data()?['role'];

      if (role == 'banned') {
        showError("Ваш аккаунт заблокирован. Обратитесь к администратору.");
        await FirebaseAuth.instance.signOut(); 
        setState(() => _isLoading = false);
        return;
      }

      if (role == null) {
        showError("Ваша роль не определена. Обратитесь к администратору.");
        await FirebaseAuth.instance.signOut(); 
        setState(() => _isLoading = false);
        return;
      }

      showSuccess("Успешный вход!");

      Future.delayed(const Duration(milliseconds: 500), () {
        switch (role) {
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'organizer':
            Navigator.pushReplacementNamed(context, '/organizerHome');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Ошибка входа");
    } catch (e) {
      showError("Ошибка при получении роли");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Вход"),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Добро пожаловать!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Пароль",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Войти",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/register'),
              child: const Text("Нет аккаунта? Зарегистрироваться"),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/reset'),
              child: const Text("Забыли пароль?"),
            ),
          ],
        ),
      ),
    );
  }
}
