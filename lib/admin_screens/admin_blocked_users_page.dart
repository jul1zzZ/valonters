import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBlockedUsersPage extends StatelessWidget {
  const AdminBlockedUsersPage({super.key});

  void unblockUser(BuildContext context, String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'user'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Пользователь разблокирован")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Заблокированные пользователи"),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 2,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'banned')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Text(
                "Нет заблокированных пользователей",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                title: Text(
                  user['name'],
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  user['email'],
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
