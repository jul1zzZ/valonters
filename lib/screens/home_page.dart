import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:valonters/screens/faq_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:valonters/screens/profile_page.dart'; 
import 'package:valonters/screens/login_page.dart'; 
import '../utils/helpers.dart';
import 'package:valonters/screens/taskhome_page.dart';
import 'package:valonters/screens/support_chat_screen.dart';

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

      Future.wait(chatSnapshot.docs.map((chatDoc) {
        return FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('senderId', isEqualTo: 'admin')
            .limit(1)
            .get();
      })).then((listOfQuerySnapshots) {
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

  Future<void> takeTaskInProgress(String taskId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
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

        final newStatus = assignedList.length >= maxPeople ? 'done' : 'open';

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
    final List<Widget> _pages = [
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
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Профиль'),
          const BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'FAQ'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                      child: const Text(
                        '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
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
    final tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'open')
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

        final tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return const Center(child: Text("Пока нет открытых заданий"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  task['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(task['description']),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
