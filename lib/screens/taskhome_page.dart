import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/helpers.dart';

class TaskHomeScreen extends StatefulWidget {
  final DocumentSnapshot task;

  // Явно добавляем параметр key в конструктор
  const TaskHomeScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  LatLng? selectedLatLng;

  Future<void> _takeTask(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'status': 'in_progress',
        'assignedTo': FirebaseAuth.instance.currentUser!.uid,
      });
      showSuccess("Задание успешно взято в работу!");
      Navigator.pop(context);
    } catch (e) {
      showError("Ошибка при взятии задания: $e");
    }
  }

  LatLng? _parseLocation(String? location) {
    if (location == null) return null;
    final parts = location.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    final data = widget.task.data() as Map<String, dynamic>;
    selectedLatLng = _parseLocation(data['location'] as String?);
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
            Text(data['title'] ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('📝 Описание:\n${data['description'] ?? 'Нет описания'}'),
            const SizedBox(height: 10),
            Text('📂 Категория: ${data['category'] ?? 'Не указано'}'),
            const SizedBox(height: 10),

            if (selectedLatLng != null) ...[
              const Text('📍 Местоположение на карте:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: MediaQuery.of(context).size.width * 0.8,
                child: FlutterMap(
                  options: MapOptions(
                    // исправлены параметры согласно новой версии flutter_map
                    initialCenter: selectedLatLng!,
                    initialZoom: 13,
                    onTap: (tapPosition, latLng) {
                      setState(() {
                        selectedLatLng = latLng;
                      });
                    },
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
                          child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ] else
              const Text('📍 Местоположение: Не указано'),

            const SizedBox(height: 10),
            Text(
                '🕒 Время проведения: ${data['eventTime'] != null ? (data['eventTime'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'Не указано'}'),
            const SizedBox(height: 10),
            Text('⏱ Примерная длительность: ${data['estimatedDuration'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('🧰 Необходимые сервисы: ${data['services'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('👤 Назначено: ${data['assignedTo'] ?? 'не назначено'}'),
            const SizedBox(height: 10),
            Text(
                '📅 Создано: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : '-'}'),
            const SizedBox(height: 10),
            Text(
                '✅ Выполнено: ${data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate().toLocal().toString().split('.')[0] : 'ещё не завершено'}'),
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
