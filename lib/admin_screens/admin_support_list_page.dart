import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_chat_screen.dart';

class AdminSupportListPage extends StatelessWidget {
  const AdminSupportListPage({super.key});

  Future<String> _getUserEmail(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['email'] ?? 'Неизвестный';
    } catch (e) {
      return 'Ошибка';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsStream = FirebaseFirestore.instance
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты с пользователями'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: chatsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text('Нет активных чатов', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final userId = chat['userId'];
              final createdAt = chat['createdAt'].toDate();
              final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(createdAt);

              return FutureBuilder<String>(
                future: _getUserEmail(userId),
                builder: (context, userSnapshot) {
                  final userEmail = userSnapshot.data ?? 'Загрузка...';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: const Icon(Icons.chat, color: Colors.deepPurple),
                      title: Text(
                        userEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Создан: $formattedDate'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminChatScreen(chatId: chat.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
