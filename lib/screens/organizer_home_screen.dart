import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganizerHomePage extends StatelessWidget {
  final String userId;

  const OrganizerHomePage({super.key, required this.userId});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
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
      case 'expired':
        return Colors.red;
      case 'in_progress':
        return Colors.amber;
      default:
        return Colors.grey;
    }
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
      case 'expired':
        return 'Отклонено';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance.collection('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Мои заявки"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksRef.where('createdBy', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final assignedCount =
                    (data['assignedToList'] as List?)?.length ?? 0;
                final max = data['maxPeople'] ?? 200;
                final status = data['status'] ?? '';
                return status != 'done' && assignedCount < max;
              }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("Нет активных заявок"));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                final title = data['title'] ?? '';
                final description = data['description'] ?? '';
                final location = data['location'] ?? '';
                final status = data['status'] ?? '';
                final assignedCount =
                    (data['assignedToList'] as List?)?.length ?? 0;
                final maxPeople = data['maxPeople'] ?? 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Место: $location",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                translateStatus(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text("Участников: $assignedCount / $maxPeople"),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.teal,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/taskDetail',
                        arguments: docs[index].data() as Map<String, dynamic>,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed:
            () => Navigator.pushNamed(context, '/addTask', arguments: userId),
      ),
    );
  }
}
