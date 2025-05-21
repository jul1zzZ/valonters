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
        SnackBar(content: Text('Статус задачи обновлен: $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Проверка фотоотчётов'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('status', isEqualTo: 'pending_review')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return Center(child: Text('Нет заявок на проверку'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;

              // Получаем base64 фотоотчёт из completionPhoto
              final String? base64Photo = data['completionPhoto'];

              Widget photoWidget;

              if (base64Photo != null && base64Photo.isNotEmpty) {
                try {
                  Uint8List bytes = base64Decode(base64Photo);
                  photoWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(bytes, height: 200, width: double.infinity, fit: BoxFit.cover),
                  );
                } catch (e) {
                  photoWidget = Text('Ошибка при загрузке фото', style: TextStyle(color: Colors.red));
                }
              } else {
                photoWidget = Text('Фотоотчет отсутствует', style: TextStyle(fontStyle: FontStyle.italic));
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Без названия',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(data['description'] ?? 'Нет описания'),
                      SizedBox(height: 10),
                      photoWidget,
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateTaskStatus(task.id, 'rejected', context),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text('Отклонить'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _updateTaskStatus(task.id, 'completed', context),
                            child: Text('Подтвердить'),
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
