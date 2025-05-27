import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/helpers.dart';

class TaskHomeScreen extends StatefulWidget {
  final DocumentSnapshot task;

  const TaskHomeScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  LatLng? selectedLatLng;

 Future<void> _takeTask(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final docRef = FirebaseFirestore.instance.collection('tasks').doc(widget.task.id);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Задание не найдено");
      }

      final data = snapshot.data()!;
      final assignedList = List<String>.from(data['assignedToList'] ?? []);
      final maxPeople = data['maxPeople'] ?? 200;

      if (assignedList.contains(uid)) {
        throw Exception("Вы уже участвуете в этом задании");
      }

      if (assignedList.length >= maxPeople) {
        throw Exception("Мест больше нет");
      }

      assignedList.add(uid);

      final newStatus = assignedList.length >= maxPeople ? 'done' : 'open';

      transaction.update(docRef, {
        'assignedToList': assignedList,
        'status': newStatus,
      });
    });

    showSuccess("Вы успешно записались на задание!");
    if (!mounted) return;
    Navigator.pop(context);
  } catch (e) {
    showError("Ошибка при записи: ${e.toString()}");
  }
}


  @override
  void initState() {
    super.initState();
    final data = widget.task.data() as Map<String, dynamic>;
    if (data['lat'] != null && data['lng'] != null) {
      selectedLatLng = LatLng(data['lat'], data['lng']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.task.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали задания')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('📝 Описание:\n${data['description'] ?? 'Нет описания'}'),
            const SizedBox(height: 10),
            Text('📂 Категория: ${data['category'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('📍 Адрес (текст): ${data['location'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            if (selectedLatLng != null) ...[
              const Text('🗺️ Местоположение на карте:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: MediaQuery.of(context).size.width * 0.9,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: selectedLatLng!,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              '🕒 Время проведения: ${data['eventTime'] != null ? (data['eventTime'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'Не указано'}',
            ),
            const SizedBox(height: 10),
            Text('⏱ Примерная длительность: ${data['estimatedDuration'] ?? 'Не указано'} ч.'),
            const SizedBox(height: 10),
            Text('🧰 Необходимые сервисы: ${data['services'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('👥 Лимит участников: ${data['maxPeople'] ?? '-'}'),
            const SizedBox(height: 10),
            Text('👤 Назначено: ${data['assignedTo'] ?? 'не назначено'}'),
            const SizedBox(height: 10),
            Text('👥 Список участников: ${data['assignedToList'] != null ? (data['assignedToList'] as List).join(', ') : 'нет'}'),
            const SizedBox(height: 10),
            Text('📅 Создано: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : '-'}'),
            const SizedBox(height: 10),
            Text('✅ Выполнено: ${data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'ещё не завершено'}'),
            const SizedBox(height: 10),
            Text('🔑 Создано пользователем: ${data['createdBy'] ?? '-'}'),
            const SizedBox(height: 24),
            const Spacer(),
            if (data['status'] == 'open')
              Center(
                child: ElevatedButton(
                  onPressed: () => _takeTask(context),
                  child: const Text("Взять в работу"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
