import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBlockedUsersPage extends StatelessWidget {
  const AdminBlockedUsersPage({super.key});

  void unblockUser(BuildContext context, String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'user'});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Пользователь разблокирован")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Заблокированные пользователи")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'banned')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("Нет заблокированных пользователей"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: TextButton(
                  onPressed: () => unblockUser(context, user.id),
                  child: const Text("Разблокировать"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
