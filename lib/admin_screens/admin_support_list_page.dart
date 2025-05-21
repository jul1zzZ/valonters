import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      appBar: AppBar(title: const Text('Чаты с пользователями')),
      body: StreamBuilder(
        stream: chatsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final userId = chat['userId'];
              final createdAt = chat['createdAt'].toDate();

              return FutureBuilder<String>(
                future: _getUserEmail(userId),
                builder: (context, userSnapshot) {
                  final userEmail = userSnapshot.data ?? 'Загрузка...';

                  return ListTile(
                    title: Text('Пользователь: $userEmail'),
                    subtitle: Text('Создан: $createdAt'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatScreen(chatId: chat.id),
                        ),
                      );
                    },
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
