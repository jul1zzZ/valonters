import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'complete_taks_screen.dart';  // убедитесь, что путь правильный

class TaskDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot task;

  TaskDetailScreen({required this.task});

  Future<void> markAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Задание помечено как выполненное!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении: $e')),
      );
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
                      )),
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
    final data = task.data() as Map<String, dynamic>;

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

            if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['photoUrl'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
              const SizedBox(height: 24),

            _buildInfoRow(Icons.description, "Описание", data['description'] ?? 'Нет описания'),
            _buildInfoRow(Icons.category, "Категория", data['category'] ?? 'Не указано'),
            _buildInfoRow(Icons.location_on, "Местоположение", data['location'] ?? 'Не указано'),
            _buildInfoRow(
              Icons.access_time,
              "Время проведения",
              data['eventTime'] != null
                  ? (data['eventTime'] as Timestamp).toDate().toLocal().toString()
                  : 'Не указано',
            ),
            _buildInfoRow(Icons.timer, "Примерная длительность", data['estimatedDuration'] ?? 'Не указано'),
            _buildInfoRow(Icons.build, "Необходимые сервисы", data['services'] ?? 'Не указано'),
            _buildInfoRow(Icons.person, "Назначено", data['assignedTo'] ?? 'не назначено'),
            _buildInfoRow(
              Icons.calendar_today,
              "Создано",
              data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate().toLocal().toString()
                  : '-',
            ),
            _buildInfoRow(
              Icons.done_all,
              "Выполнено",
              data['completedAt'] != null
                  ? (data['completedAt'] as Timestamp).toDate().toLocal().toString()
                  : 'ещё не завершено',
            ),
            _buildInfoRow(Icons.vpn_key, "Создано пользователем", data['createdBy'] ?? '-'),

            const SizedBox(height: 30),

            if (data['status'] != 'completed')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompleteTaskScreen(taskId: task.id),
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
