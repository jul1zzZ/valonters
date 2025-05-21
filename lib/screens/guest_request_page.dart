import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

class GuestRequestPage extends StatefulWidget {
  const GuestRequestPage({super.key});

  @override
  State<GuestRequestPage> createState() => _GuestRequestPageState();
}

class _GuestRequestPageState extends State<GuestRequestPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController(); // новое поле
  final requestController = TextEditingController();

  bool isLoading = false;

  Future<void> submitRequest() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final contact = contactController.text.trim();
    final requestText = requestController.text.trim();

    if (name.isEmpty || email.isEmpty || requestText.isEmpty || contact.isEmpty) {
      showError("Пожалуйста, заполните все поля, включая контактную информацию");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final guestRef = await FirebaseFirestore.instance.collection('guests').add({
        'name': name,
        'email': email,
        'contact': contact, // сохраняем контакт
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('guest_tasks').add({
        'guestId': guestRef.id,
        'title': requestText,
        'status': 'на рассмотрении',
        'createdAt': FieldValue.serverTimestamp(),
      });

      showSuccess("Заявка успешно отправлена!");

      Navigator.pop(context);
    } catch (e) {
      showError("Ошибка при отправке заявки");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Оставить заявку")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Ваше имя"),
                textInputAction: TextInputAction.next,
                autocorrect: true,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: "Контакт (Telegram, телефон или почта)",
                ),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: requestController,
                decoration: InputDecoration(labelText: "Описание заявки"),
                maxLines: 4,
                textInputAction: TextInputAction.done,
                autocorrect: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: submitRequest,
                      child: Text("Отправить заявку"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
