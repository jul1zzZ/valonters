import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  Future<List<DocumentSnapshot>> getUserTasks(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();
    return snapshot.docs;
  }

  void showUserTasks(BuildContext context, String userId, String userName) async {
    final tasks = await getUserTasks(userId);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Заявки пользователя $userName"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tasks
                .map((task) => ListTile(
                      title: Text(task['title']),
                      subtitle: Text("Статус: ${task['status']}"),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  void banUser(String userId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': 'banned'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пользователь заблокирован (роль изменена на banned)")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при блокировке: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Пользователи и их заявки")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final role = user.data().containsKey('role') ? user['role'] : 'user';
              final bool isBanned = role == 'banned';

              return ListTile(
                title: Text(user['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email']),
                    if (isBanned)
                      const Text("Заблокирован", style: TextStyle(color: Colors.red)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => showUserTasks(context, user.id, user['name']),
                      child: const Text("Заявки"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isBanned ? null : () => banUser(user.id, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Блок"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
