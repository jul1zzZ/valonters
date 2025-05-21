import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'taskdetail_page.dart';
import 'package:valonters/screens/complete_taks_screen.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _getUserData() async {
    final user = _auth.currentUser;
    final userDoc = await _firestore.collection('users').doc(user?.uid).get();
    return userDoc.data() ?? {};
  }

  Stream<QuerySnapshot> _getUserTasks() {
    final user = _auth.currentUser;
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user?.uid)
        .snapshots();
  }

  String translateStatus(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'pending_review':
        return 'На проверке';
      case 'completed':
        return 'Выполнено';
      case 'rejected':
        return 'Отклонено';
      case 'in_progress':
        return 'В процессе';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange.shade200;
      case 'pending_review':
        return Colors.blue.shade200;
      case 'completed':
        return Colors.green.shade200;
      case 'rejected':
        return Colors.red.shade200;
      case 'in_progress':
        return Colors.orange.shade300;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Профиль')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final userData = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                SizedBox(height: 8),
                Text(userData['name'] ?? '', style: TextStyle(fontSize: 18)),
                Text(user?.email ?? ''),
                Text('Телефон: ${userData['phone'] ?? 'не указан'}'),
                Text('Дата регистрации: ${userData['registrationDate'] != null ? (userData['registrationDate'] as Timestamp).toDate().toLocal() : 'не указана'}'),
                Text('Роль: ${userData['role'] ?? ''}'),
                SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getUserTasks(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();

                      final tasks = snapshot.data!.docs;
                      final completedTasks = tasks.where((task) {
                        final data = task.data() as Map<String, dynamic>?;
                        return data != null && data['status'] == 'completed';
                      }).toList();

                      final sortedTasks = List.from(tasks)..sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>?;
                        final dataB = b.data() as Map<String, dynamic>?;
                        final statusA = dataA?['status'] ?? '';
                        final statusB = dataB?['status'] ?? '';
                        if (statusA == statusB) return 0;
                        if (statusA == 'completed') return 1;
                        if (statusB == 'completed') return -1;
                        return 0;
                      });

                      // Подсчёт суммарных часов по completed задачам
                      double totalWorkedHours = 0;
for (var task in completedTasks) {
  final data = task.data() as Map<String, dynamic>?;
  if (data != null && data.containsKey('estimatedDuration')) {
    final duration = data['estimatedDuration'];
    if (duration is int) {
      totalWorkedHours += duration.toDouble();
    } else if (duration is double) {
      totalWorkedHours += duration;
    } else if (duration is String) {
      // Пробуем парсить строку в число
      final parsed = double.tryParse(duration);
      if (parsed != null) {
        totalWorkedHours += parsed;
      }
    }
  }
}

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Выполнено заявок: ${completedTasks.length}'),
                          Text('Всего заявок: ${tasks.length}'),
                          Text('Отработано часов: ${totalWorkedHours.toStringAsFixed(1)}'),
                          Divider(),
                          Text('История заявок:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                final task = sortedTasks[index];
                                final data = task.data() as Map<String, dynamic>?;
                                final status = data?['status'] ?? '';
                                return Card(
                                  child: ListTile(
                                    title: Text(data?['title'] ?? ''),
                                    subtitle: Text(data?['description'] ?? ''),
                                    trailing: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 56,
                                        maxWidth: 120,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(status),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              translateStatus(status),
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          if (status == 'active' || status == 'in_progress')
                                            SizedBox(
                                              height: 28,
                                              child: TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: Size(0, 28),
                                                ),
                                                child: Text('Завершить', style: TextStyle(fontSize: 12)),
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TaskDetailScreen(task: task),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
