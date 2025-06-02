import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'complete_taks_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String creatorName = '';

  @override
  void initState() {
    super.initState();
    fetchCreatorName();
  }

  Future<void> fetchCreatorName() async {
    final data = widget.task.data() as Map<String, dynamic>;
    final createdBy = data['createdBy'];
    if (createdBy != null && createdBy is String) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(createdBy)
              .get();
      if (userDoc.exists) {
        setState(() {
          creatorName = userDoc.data()?['name'] ?? createdBy;
        });
      } else {
        setState(() {
          creatorName = createdBy;
        });
      }
    }
  }

  Future<void> markAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .update({'status': 'completed', 'completedAt': Timestamp.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задание помечено как выполненное!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при обновлении: $e')));
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.task.data() as Map<String, dynamic>;
    final double? lat = double.tryParse(data['lat']?.toString() ?? '');
    final double? lng = double.tryParse(data['lng']?.toString() ?? '');
    final LatLng? point =
        (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали заявки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'] ?? 'Без названия',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),

            if (data['photoUrl'] != null &&
                data['photoUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['photoUrl'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (data['photoUrl'] != null &&
                data['photoUrl'].toString().isNotEmpty)
              const SizedBox(height: 24),

            _buildInfoRow(
              Icons.description,
              "Описание",
              data['description'] ?? 'Нет описания',
            ),
            _buildInfoRow(
              Icons.category,
              "Категория",
              data['category'] ?? 'Не указано',
            ),
            _buildInfoRow(
              Icons.location_on,
              "Адрес",
              data['location'] ?? 'Не указано',
            ),
            _buildInfoRow(
              Icons.access_time,
              "Время проведения",
              data['eventTime'] != null
                  ? (data['eventTime'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                  : 'Не указано',
            ),
            _buildInfoRow(
              Icons.timer,
              "Примерная длительность",
              data['estimatedDuration'] ?? 'Не указано',
            ),
            _buildInfoRow(
              Icons.build,
              "Необходимые сервисы",
              data['services'] ?? 'Не указано',
            ),
            _buildInfoRow(
              Icons.group,
              "Ограничение по людям",
              '${data['maxPeople'] ?? '-'}',
            ),
            _buildInfoRow(
              Icons.person,
              "Назначено",
              data['assignedTo'] ?? 'не назначено',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              "Создано",
              data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                  : '-',
            ),
            _buildInfoRow(
              Icons.done_all,
              "Выполнено",
              data['completedAt'] != null
                  ? (data['completedAt'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                  : 'ещё не завершено',
            ),
            _buildInfoRow(
              Icons.vpn_key,
              "Создано пользователем",
              creatorName.isNotEmpty ? creatorName : 'загрузка...',
            ),

            const SizedBox(height: 20),

            if (point != null) ...[
              const SizedBox(height: 10),
              const Text(
                "Местоположение на карте:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
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
              const SizedBox(height: 20),
            ] else ...[
              const Text(
                "Местоположение не указано",
                style: TextStyle(color: Colors.grey),
              ),
            ],

            if (data['status'] != 'completed')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      "Завершить задание",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    final Timestamp? eventTimestamp = data['eventTime'];
                    if (eventTimestamp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Время начала мероприятия не указано'),
                        ),
                      );
                      return;
                    }

                    final DateTime eventTime =
                        eventTimestamp.toDate().toLocal();
                    final DateTime now = DateTime.now();

                    if (now.isBefore(eventTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Задание ещё не началось. Вы сможете завершить его после ${eventTime.toString().substring(0, 16)}',
                          ),
                        ),
                      );
                      return;
                    }

                    // Переход на экран завершения задания
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CompleteTaskScreen(taskId: widget.task.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
