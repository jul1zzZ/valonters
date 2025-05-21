import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final settingsDoc = firestore.collection('settings').doc('init');

  final snapshot = await settingsDoc.get();

  if (!snapshot.exists) {
    debugPrint("🔥 Firestore: начинаем инициализацию...");

    await settingsDoc.set({'initialized': true, 'timestamp': FieldValue.serverTimestamp()});

    final categories = [
      {'name': 'Доставка еды', 'icon': '🍞'},
      {'name': 'Покупка лекарств', 'icon': '💊'},
      {'name': 'Помощь по дому', 'icon': '🧹'},
      {'name': 'Сопровождение', 'icon': '🚶'},
    ];

    for (var category in categories) {
      await firestore.collection('categories').add(category);
    }

    final coordinatorRef = await firestore.collection('users').add({
      'name': 'Админ Координатор',
      'email': 'admin@volunteer.org',
      'role': 'coordinator',
      'phone': '+79000000000',
      'registrationDate': FieldValue.serverTimestamp(),
    });

    await firestore.collection('tasks').add({
      'title': 'Помочь с доставкой еды',
      'description': 'Принести продукты бабушке на Пушкина 12',
      'status': 'open',
      'location': 'г. Москва, ул. Пушкина, д. 12',
      'createdBy': coordinatorRef.id,
      'assignedTo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'category': 'Доставка еды',
    });

    debugPrint("✅ Firestore успешно инициализирован!");
  } else {
    debugPrint("✅ Firestore уже инициализирован");
  }
}

