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
  final contactController = TextEditingController();
  final requestController = TextEditingController();
  final locationController = TextEditingController();
  final durationController = TextEditingController();
  final servicesController = TextEditingController();

  bool isLoading = false;

  Future<void> submitRequest() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final contact = contactController.text.trim();
    final requestText = requestController.text.trim();
    final location = locationController.text.trim();
    final estimatedDuration = durationController.text.trim();
    final services = servicesController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        contact.isEmpty ||
        requestText.isEmpty ||
        location.isEmpty ||
        estimatedDuration.isEmpty ||
        services.isEmpty) {
      showError("Пожалуйста, заполните все поля");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final guestRef = await FirebaseFirestore.instance.collection('guests').add({
        'name': name,
        'email': email,
        'contact': contact,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('guest_tasks').add({
        'guestId': guestRef.id,
        'title': requestText,
        'description': requestText,
        'status': 'на рассмотрении',
        'location': location,
        'estimatedDuration': estimatedDuration,
        'services': services,
        'createdBy': name,
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Оставить заявку"),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Заполните форму заявки",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: _inputDecoration("Ваше имя"),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: _inputDecoration("Email"),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contactController,
              decoration: _inputDecoration("Контакт (Telegram, телефон или почта)"),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: _inputDecoration("Местоположение"),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              decoration: _inputDecoration("Примерная длительность (в минутах)"),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: servicesController,
              decoration: _inputDecoration("Необходимые сервисы"),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: requestController,
              decoration: _inputDecoration("Описание заявки"),
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 30),
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Отправить заявку",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
