import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatScreen extends StatefulWidget {
  final String chatId;
  const AdminChatScreen({super.key, required this.chatId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final Map<String, Map<String, String>> _userCache = {
    'admin': {
      'name': 'Администратор',
      'avatarUrl': '', // сюда можно вставить URL или оставить пустым
    },
  };

  Future<Map<String, String>> _getUserInfo(String userId) async {
  if (_userCache.containsKey(userId)) return _userCache[userId]!;

  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = userDoc.data();
    final name = data?['name'] ?? 'Без имени';
    final avatarUrl = data?['avatarUrl'] ?? '';
    final Map<String, String> info = {
      'name': name,
      'avatarUrl': avatarUrl,
    };
    _userCache[userId] = info;
    return info;
  } catch (e) {
    return {'name': 'Ошибка', 'avatarUrl': ''};
  }
  }


  void sendMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': 'admin',
      'senderRole': 'admin',
      'text': text,
      'timestamp': Timestamp.now(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с пользователем')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderId = msg['senderId'];
                    final isAdmin = msg['senderRole'] == 'admin';

                    return FutureBuilder<Map<String, String>>(
                      future: _getUserInfo(senderId),
                      builder: (context, userSnapshot) {
                        final name = userSnapshot.data?['name'] ?? 'Загрузка...';
                        final avatarUrl = userSnapshot.data?['avatarUrl'] ?? '';

                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            child: Row(
                              mainAxisAlignment:
                                  isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isAdmin)
                                  CircleAvatar(
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                                  ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isAdmin
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isAdmin ? Colors.green[100] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(msg['text']),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin)
                                  const SizedBox(width: 8),
                                if (isAdmin)
                                  const CircleAvatar(
                                    child: Icon(Icons.admin_panel_settings),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
