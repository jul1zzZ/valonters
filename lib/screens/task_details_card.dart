import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/helpers.dart';

class TaskDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final LatLng? selectedLatLng;

  const TaskDetailsCard({
    super.key,
    required this.data,
    required this.selectedLatLng,
  });

  String formatDate(Timestamp? ts) {
    return ts != null
        ? ts.toDate().toLocal().toString().split('.')[0]
        : 'Не указано';
  }

  @override
  Widget build(BuildContext context) {
    final assignedList = List<String>.from(data['assignedToList'] ?? []);

    return Column(
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
        Text('🕒 Время проведения: ${formatDate(data['eventTime'])}'),
        const SizedBox(height: 10),
        Text(
          '⏱ Примерная длительность: ${(data['estimatedDuration'] is num) ? '${data['estimatedDuration']} ч.' : 'Не указано'}',
        ),
        const SizedBox(height: 10),
        Text('🧰 Необходимые сервисы: ${data['services'] ?? 'Не указано'}'),
        const SizedBox(height: 10),
        Text('👥 Лимит участников: ${data['maxPeople'] ?? '-'}'),
        const SizedBox(height: 10),
        Text('👤 Назначено: ${data['assignedTo'] ?? 'не назначено'}'),
        const SizedBox(height: 10),
        Text(
          '👥 Список участников: ${assignedList.isNotEmpty ? assignedList.join(', ') : 'нет'}',
        ),
        const SizedBox(height: 10),
        Text('📅 Создано: ${formatDate(data['createdAt'])}'),
        const SizedBox(height: 10),
        Text('✅ Выполнено: ${formatDate(data['completedAt'])}'),
        const SizedBox(height: 10),
        Text('🔑 Создано пользователем: ${data['createdBy'] ?? '-'}'),
      ],
    );
  }
}
