import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGuestPage extends StatelessWidget {
  const AdminGuestPage({super.key});

  Future<List<DocumentSnapshot>> getGuestTasks(String guestId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('guest_tasks')
        .where('guestId', isEqualTo: guestId)
        .get();
    return snapshot.docs;
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('guest_tasks')
        .doc(taskId)
        .update({'status': newStatus});
  }

  Future<void> acceptTask(String taskId) async {
    final taskDoc = await FirebaseFirestore.instance.collection('guest_tasks').doc(taskId).get();
    if (!taskDoc.exists) return;

    final taskData = taskDoc.data()!;
    final guestId = taskData['guestId'];

    final guestDoc = await FirebaseFirestore.instance.collection('guests').doc(guestId).get();
    final guestData = guestDoc.exists ? guestDoc.data()! : {};

    await FirebaseFirestore.instance.collection('guest_tasks').doc(taskId).update({'status': 'принята'});

    await FirebaseFirestore.instance.collection('tasks').add({
      'title': taskData['title'] ?? '',
      'description': 'Контакт для связи: ${guestData['contact'] ?? ''}',
      'services': taskData['services'] ?? '',
      'location': taskData['location'] ?? '',
      'estimatedDuration': taskData['estimatedDuration'] ?? '',
      'eventTime': taskData['eventTime'] ?? FieldValue.serverTimestamp(),
      'photoUrl': taskData['photoUrl'] ?? '',
      'createdAt': taskData['createdAt'] ?? FieldValue.serverTimestamp(),
      'status': 'open',
      'guestId': guestId,
      'guestName': guestData['name'] ?? '',
      'guestEmail': guestData['email'] ?? '',
      'guestContact': guestData['contact'] ?? '',
    });
  }

  void showGuestTasks(BuildContext context, String guestId, String guestName) async {
    final tasks = await getGuestTasks(guestId);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Заявки гостя $guestName",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tasks.map((task) {
              final status = task['status'] ?? 'на рассмотрении';
              Color statusColor;
              switch (status) {
                case 'принята':
                case 'open':
                  statusColor = Colors.green;
                  break;
                case 'отклонена':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(
                    task['title'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Статус: $status",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      )),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'на рассмотрении') ...[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Принять',
                          onPressed: () async {
                            await acceptTask(task.id);
                            Navigator.pop(context);
                            showGuestTasks(context, guestId, guestName);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Отклонить',
                          onPressed: () async {
                            await updateTaskStatus(task.id, 'отклонена');
                            Navigator.pop(context);
                            showGuestTasks(context, guestId, guestName);
                          },
                        ),
                      ] else
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Закрыть",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Гости и их заявки",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('guests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final guests = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: guests.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
            itemBuilder: (context, index) {
              final guest = guests[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    guest['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    guest['email'],
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    onPressed: () => showGuestTasks(context, guest.id, guest['name']),
                    child: const Text(
                      "Заявки",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
