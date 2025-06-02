import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:valonters/screens/faq_page.dart';
import 'package:valonters/screens/login_page.dart';
import 'package:valonters/screens/profile_page.dart';
import 'package:valonters/screens/support_chat_screen.dart';
import 'package:valonters/screens/taskhome_page.dart';
import '../utils/helpers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _listenUnreadMessages();
    _expireOldTasks();
  }

  void _expireOldTasks() async {
    final now = DateTime.now();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('tasks')
            .where('status', isEqualTo: 'open')
            .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final eventTime = (data['eventTime'] as Timestamp?)?.toDate();

      if (eventTime != null) {
        final difference = now.difference(eventTime);
        if (difference.inHours > 24) {
          await doc.reference.update({'status': 'expired'});
        }
      }
    }
  }

  void _listenUnreadMessages() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('chats')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((chatSnapshot) {
          if (chatSnapshot.docs.isEmpty) {
            if (_hasUnreadMessages) {
              setState(() {
                _hasUnreadMessages = false;
              });
            }
            return;
          }

          Future.wait(
            chatSnapshot.docs.map((chatDoc) {
              return FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatDoc.id)
                  .collection('messages')
                  .where('isRead', isEqualTo: false)
                  .where('senderId', isEqualTo: 'admin')
                  .limit(1)
                  .get();
            }),
          ).then((listOfQuerySnapshots) {
            bool hasUnread = false;
            for (var querySnap in listOfQuerySnapshots) {
              if (querySnap.docs.isNotEmpty) {
                hasUnread = true;
                break;
              }
            }

            if (_hasUnreadMessages != hasUnread) {
              setState(() {
                _hasUnreadMessages = hasUnread;
              });
            }
          });
        });
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<bool> canTakeNewTask(String userId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedToList', arrayContains: userId)
            .where('status', whereIn: ['open', 'in_progress'])
            .get();

    return querySnapshot.docs.isEmpty;
  }

  Future<void> takeTaskInProgress(String taskId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 👉 Добавляем проверку
    final canTake = await canTakeNewTask(uid);
    if (!canTake) {
      showError("Вы не можете взять новую заявку, пока не завершите текущую");
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('tasks').doc(taskId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("Заявка не найдена");

        final data = snapshot.data()!;
        final assignedList = List<String>.from(data['assignedToList'] ?? []);
        final maxPeople = data['maxPeople'] ?? 200;

        if (assignedList.contains(uid)) {
          throw Exception("Вы уже записаны на это задание");
        }

        if (assignedList.length >= maxPeople) {
          throw Exception("Мест больше нет");
        }

        assignedList.add(uid);

        final newStatus =
            assignedList.length >= maxPeople ? 'done' : 'in_progress';

        transaction.update(docRef, {
          'assignedToList': assignedList,
          'status': newStatus,
        });
      });

      showSuccess("Вы успешно записались на задание");
    } catch (e) {
      showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TaskPage(onTakeTask: takeTaskInProgress),
      ProfileScreen(),
      const FaqPage(),
      SupportChatScreen(userId: FirebaseAuth.instance.currentUser!.uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Добро пожаловать!"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Профиль',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'FAQ',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Чат',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class TaskPage extends StatelessWidget {
  final Future<void> Function(String taskId) onTakeTask;

  const TaskPage({super.key, required this.onTakeTask});

  @override
  Widget build(BuildContext context) {
    final tasksStream =
        FirebaseFirestore.instance
            .collection('tasks')
            .where('status', whereIn: ['open', 'in_progress'])
            .orderBy('createdAt', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Ошибка загрузки заданий"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final tasks =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['eventTime'] != null) {
                final startTime = (data['eventTime'] as Timestamp).toDate();
                if (startTime.isBefore(now)) {
                  if (data['status'] == 'open') {
                    final difference = now.difference(startTime);
                    return difference.inHours < 24;
                  }
                  return false;
                }
              }
              return true;
            }).toList();

        if (tasks.isEmpty) {
          return const Center(child: Text("Нет актуальных заданий"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final data = task.data() as Map<String, dynamic>;

            final location = data['location'] ?? 'Адрес не указан';
            final startTime =
                data['eventTime'] != null
                    ? (data['eventTime'] as Timestamp).toDate()
                    : null;
            final duration = data['duration'];
            final estimatedDuration = data['estimatedDuration'];

            String formattedStartTime =
                startTime != null
                    ? "${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.${startTime.year} в ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}"
                    : "Время не указано";

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data['title'] ?? 'Без названия',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 8),
                      Text("📍 Адрес: $location"),
                      Text("🕒 Время: $formattedStartTime"),
                      if (duration != null)
                        Text("⏱ Длительность: $duration ч."),
                      if (estimatedDuration != null)
                        Text(
                          "📌 Оценочная длительность: $estimatedDuration ч.",
                        ),
                    ],
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Взять"),
                  onPressed: () => onTakeTask(task.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskHomeScreen(task: task),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
