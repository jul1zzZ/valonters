import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatScreen extends StatefulWidget {
  final String userId;
  const SupportChatScreen({super.key, required this.userId});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, Map<String, dynamic>> _userCache = {}; // Кэш: userId → {name, photoUrl}

  void sendMessage(String text) async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(widget.userId);
    await chatDoc.set({'userId': widget.userId, 'createdAt': Timestamp.now()}, SetOptions(merge: true));
    await chatDoc.collection('messages').add({
      'senderId': widget.userId,
      'senderRole': 'user',
      'text': text,
      'timestamp': Timestamp.now(),
    });
    _controller.clear();
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data() ?? {'name': 'Неизвестный', 'photoUrl': null};

    _userCache[userId] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с поддержкой')),
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
                    final isUser = msg['senderRole'] == 'user';
                    final senderId = msg['senderId'];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getUserData(senderId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox(); // Пусто, пока загружается
                        }

                        final user = userSnapshot.data!;
                        final userName = user['name'] ?? 'Неизвестный';
                        final photoUrl = user['photoUrl'];

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Row(
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isUser) _buildAvatar(photoUrl, userName),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.only(top: 5),
                                        decoration: BoxDecoration(
                                          color: isUser ? Colors.blue[100] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(msg['text']),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUser) _buildAvatar(photoUrl, userName),
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

  Widget _buildAvatar(String? photoUrl, String name) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      return CircleAvatar(
        radius: 18,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
      );
    }
  }
}
