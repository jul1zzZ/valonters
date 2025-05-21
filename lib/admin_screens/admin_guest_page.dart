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

  // Получаем данные гостя
  final guestDoc = await FirebaseFirestore.instance.collection('guests').doc(guestId).get();
  final guestData = guestDoc.exists ? guestDoc.data()! : {};

  // Обновляем статус гостевой заявки
  await FirebaseFirestore.instance.collection('guest_tasks').doc(taskId).update({'status': 'принята'});

  // Создаём новую заявку в основной коллекции с корректной структурой
  await FirebaseFirestore.instance.collection('tasks').add({
    'title': taskData['title'] ?? '',
    'description': 'Контакт для связи: ${guestData['contact'] ?? ''}', // Вставляем контакт в description
    'services': taskData['services'] ?? '',
    'location': taskData['location'] ?? '',
    'estimatedDuration': taskData['estimatedDuration'] ?? '',
    'eventTime': taskData['eventTime'] ?? FieldValue.serverTimestamp(),
    'photoUrl': taskData['photoUrl'] ?? '',
    'createdAt': taskData['createdAt'] ?? FieldValue.serverTimestamp(),
    'status': 'open', // Статус новой задачи — "open"
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
        title: Text("Заявки гостя $guestName"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tasks.map((task) {
              final status = task['status'] ?? 'на рассмотрении';
              return ListTile(
                title: Text(task['title']),
                subtitle: Text("Статус: $status"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'на рассмотрении') ...[
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        tooltip: 'Принять',
                        onPressed: () async {
                          await acceptTask(task.id);
                          Navigator.pop(context);
                          showGuestTasks(context, guestId, guestName);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
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
                          color: status == 'open' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрыть")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Гости и их заявки")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('guests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final guests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: guests.length,
            itemBuilder: (context, index) {
              final guest = guests[index];
              return ListTile(
                title: Text(guest['name']),
                subtitle: Text(guest['email']),
                trailing: TextButton(
                  onPressed: () => showGuestTasks(context, guest.id, guest['name']),
                  child: const Text("Заявки"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
