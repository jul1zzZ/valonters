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

  @override
  Widget build(BuildContext context) {
    final data = task.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали заявки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Без названия',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['photoUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),
            Text('📝 Описание:\n${data['description'] ?? 'Нет описания'}'),
            const SizedBox(height: 10),
            Text('📂 Категория: ${data['category'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('📍 Местоположение: ${data['location'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('🕒 Время проведения: ${data['eventTime'] != null ? (data['eventTime'] as Timestamp).toDate().toLocal().toString() : 'Не указано'}'),
            const SizedBox(height: 10),
            Text('⏱ Примерная длительность: ${data['estimatedDuration'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('🧰 Необходимые сервисы: ${data['services'] ?? 'Не указано'}'),
            const SizedBox(height: 10),
            Text('👤 Назначено: ${data['assignedTo'] ?? 'не назначено'}'),
            const SizedBox(height: 10),
            Text('📅 Создано: ${data['createdAt']?.toDate()?.toLocal() ?? '-'}'),
            const SizedBox(height: 10),
            Text('✅ Выполнено: ${data['completedAt']?.toDate()?.toLocal() ?? 'ещё не завершено'}'),
            const SizedBox(height: 10),
            Text('🔑 Создано пользователем: ${data['createdBy'] ?? '-'}'),
            const SizedBox(height: 24),

            if (data['status'] != 'completed')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Завершить"),
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
