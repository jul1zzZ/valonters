import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  Future<List<DocumentSnapshot>> getUserTasks(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedToList', arrayContains: userId)
            .get();
    return snapshot.docs;
  }

  void showUserTasks(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    final tasks = await getUserTasks(userId);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Заявки пользователя $userName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  tasks.isEmpty
                      ? const Text(
                        "Нет заявок",
                        style: TextStyle(color: Colors.grey),
                      )
                      : ListView(
                        shrinkWrap: true,
                        children:
                            tasks.map((task) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    task['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Статус: ${translateStatus(task['status'])}",
                                    style: const TextStyle(color: Colors.grey),
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

  String translateStatus(String status) {
    switch (status) {
      case 'pending_review':
        return 'Ожидает проверки';
      case 'in_progress':
        return 'В процессе';
      case 'completed':
        return 'Завершено';
      case 'expired':
        return 'Истек срок';
      case 'cancelled':
        return 'Отменено';
      case 'open':
        return 'Открыто';
      default:
        return 'Неизвестно';
    }
  }

  void banUser(String userId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': 'banned',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пользователь заблокирован")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка при блокировке: $e")));
    }
  }

  void changeRole(String userId, String newRole, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Роль изменена на $newRole")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка при смене роли: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Пользователи и заявки",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final role =
                  user.data().containsKey('role') ? user['role'] : 'user';
              final bool isBanned = role == 'banned';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (isBanned)
                        const Text(
                          "Заблокирован",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (!isBanned)
                        Row(
                          children: [
                            const Text(
                              "Роль: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: role,
                              onChanged: (newRole) {
                                if (newRole != null) {
                                  changeRole(user.id, newRole, context);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Админ'),
                                ),
                                DropdownMenuItem(
                                  value: 'volunteer',
                                  child: Text('Волонтёр'),
                                ),
                                DropdownMenuItem(
                                  value: 'organizer',
                                  child: Text('Организатор'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed:
                                () => showUserTasks(
                                  context,
                                  user.id,
                                  user['name'],
                                ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Заявки"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed:
                                isBanned
                                    ? null
                                    : () => banUser(user.id, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Блок"),
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
