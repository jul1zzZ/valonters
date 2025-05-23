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

  String translateRole(String role) {
    switch (role) {
      case 'volunteer':
        return 'Волонтёр';
      case 'admin':
        return 'Администратор';
      case 'guest':
        return 'Гость';
      default:
        return role;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange;
      case 'pending_review':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_progress':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 8),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final userData = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(userData['name'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(user?.email ?? '', style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.phone, 'Телефон', userData['phone'] ?? 'не указан'),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Дата регистрации',
                          userData['registrationDate'] != null
                              ? (userData['registrationDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                              : 'не указана',
                        ),
                        _buildInfoRow(Icons.badge, 'Роль', translateRole(userData['role'] ?? '')),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getUserTasks(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                      final tasks = snapshot.data!.docs;
                      final completedTasks = tasks.where((task) {
                        final data = task.data() as Map<String, dynamic>?;
                        return data != null && data['status'] == 'completed';
                      }).toList();

                      double totalWorkedHours = 0;
                      for (var task in completedTasks) {
                        final data = task.data() as Map<String, dynamic>?;
                        if (data != null && data.containsKey('estimatedDuration')) {
                          final duration = data['estimatedDuration'];
                          if (duration is int) totalWorkedHours += duration.toDouble();
                          else if (duration is double) totalWorkedHours += duration;
                          else if (duration is String) {
                            final parsed = double.tryParse(duration);
                            if (parsed != null) totalWorkedHours += parsed;
                          }
                        }
                      }

                      final sortedTasks = List.from(tasks)..sort((a, b) {
                        final statusA = (a.data() as Map)['status'] ?? '';
                        final statusB = (b.data() as Map)['status'] ?? '';
                        if (statusA == 'completed') return 1;
                        if (statusB == 'completed') return -1;
                        return 0;
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Выполнено заявок: ${completedTasks.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Всего заявок: ${tasks.length}'),
                          Text('Отработано часов: ${totalWorkedHours.toStringAsFixed(1)}'),
                          SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                final task = sortedTasks[index];
                                final data = task.data() as Map<String, dynamic>?;
                                final status = data?['status'] ?? '';

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(12),
                                    title: Text(data?['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(data?['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                        SizedBox(height: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(status),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            translateStatus(status),
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: (status == 'active' || status == 'in_progress')
                                        ? ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CompleteTaskScreen(taskId: task.id),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text('Завершить', style: TextStyle(fontSize: 12)),
                                          )
                                        : null,
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
