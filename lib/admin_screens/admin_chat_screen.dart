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
      'avatarUrl': '',
    },
  };

Future<Map<String, String>> _getUserInfo(String userId) async {
  if (_userCache.containsKey(userId)) return _userCache[userId]!;

  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = userDoc.data();
    final name = data?['name']?.toString() ?? 'Без имени';
    final avatarUrl = data?['avatarUrl']?.toString() ?? '';
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


  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': 'admin',
      'senderRole': 'admin',
      'text': text.trim(),
      'timestamp': Timestamp.now(),
      'isRead': false, 
    });
    _controller.clear();
  }

  /// Помечаем все непрочитанные сообщения от пользователя как прочитанные админом
  Future<void> _markMessagesAsRead() async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    final unreadSnapshot = await messagesRef
        .where('senderRole', isEqualTo: 'user')
        .where('isReadByAdmin', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isReadByAdmin': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с пользователем'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;

                // Помечаем входящие сообщения как прочитанные
                _markMessagesAsRead();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Нет сообщений",
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderId = msg['senderId'] as String;
                    final senderRole = msg['senderRole'] as String;
                    final isAdmin = senderRole == 'admin';
                    final text = msg['text'] as String;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isAdmin)
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                    child: avatarUrl.isEmpty
                                        ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                                        : null,
                                  ),
                                if (!isAdmin) const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isAdmin
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? theme.colorScheme.primaryContainer
                                              : theme.colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: Radius.circular(isAdmin ? 12 : 0),
                                            bottomRight: Radius.circular(isAdmin ? 0 : 12),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 3,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          text,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin) const SizedBox(width: 8),
                                if (isAdmin)
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Icon(
                                      Icons.admin_panel_settings,
                                      color: theme.colorScheme.onPrimary,
                                    ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: theme.colorScheme.surfaceVariant,
                      filled: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                  tooltip: 'Отправить',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
