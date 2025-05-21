import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/helpers.dart';

class ResetPasswordPage extends StatelessWidget {
  ResetPasswordPage({super.key});

  final emailController = TextEditingController();

  void resetPassword(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      showSuccess("Письмо с восстановлением отправлено!");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Ошибка восстановления пароля");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Восстановление пароля")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => resetPassword(context),
              child: Text("Восстановить пароль"),
            ),
          ],
        ),
      ),
    );
  }
}
