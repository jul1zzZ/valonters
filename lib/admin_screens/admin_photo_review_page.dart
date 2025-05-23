import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPhotoReviewScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateTaskStatus(String taskId, String newStatus, BuildContext context) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'reviewedAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус задачи обновлён: $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка фотоотчётов'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('status', isEqualTo: 'pending_review')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'Нет заявок на проверку',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;

              final String? base64Photo = data['completionPhoto'];
              Widget photoWidget;

              if (base64Photo != null && base64Photo.isNotEmpty) {
                try {
                  Uint8List bytes = base64Decode(base64Photo);
                  photoWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      bytes,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                } catch (e) {
                  photoWidget = const Text(
                    'Ошибка при загрузке фото',
                    style: TextStyle(color: Colors.red),
                  );
                }
              } else {
                photoWidget = const Text(
                  'Фотоотчет отсутствует',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                );
              }

              return Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Без названия',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['description'] ?? 'Нет описания',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      photoWidget,
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _updateTaskStatus(task.id, 'rejected', context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Отклонить'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _updateTaskStatus(task.id, 'completed', context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Подтвердить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
