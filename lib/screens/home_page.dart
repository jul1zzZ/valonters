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

  Future<void> addSampleTasks() async {
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();

    final tasks = [
      {"title": "Раздать еду бездомным", "description": "Помочь с раздачей горячей еды на вокзале."},
      {"title": "Помощь пожилому соседу", "description": "Сходить в магазин и аптеку по списку."},
      {"title": "Уборка в парке", "description": "Присоединиться к субботнику в Парке Победы."},
      {"title": "Поддержка на мероприятии", "description": "Помочь с организацией благотворительного концерта."},
      {"title": "Разнести листовки", "description": "Распространить листовки о сборе помощи по району."},
      {"title": "Сбор одежды", "description": "Сортировать вещи для передачи нуждающимся."},
      {"title": "Наставник школьника", "description": "Провести час с ребёнком из неблагополучной семьи."},
      {"title": "Онлайн поддержка", "description": "Поговорить с пожилыми людьми по телефону."},
      {"title": "Уборка территории приюта", "description": "Убрать двор и помещения приюта."},
      {"title": "Помощь на кухне", "description": "Порезать овощи и помочь на кухне волонтёрского центра."},
      {"title": "Организация игр", "description": "Провести игры для детей из детского дома."},
      {"title": "Сопровождение на прогулке", "description": "Прогулка с инвалидами-колясочниками по скверу."},
      {"title": "Проверка аптечек", "description": "Проверить и пополнить аптечки в общественных местах."},
      {"title": "Фотограф на мероприятие", "description": "Сделать фотографии с праздника в Доме ветеранов."},
      {"title": "Ремонт детской площадки", "description": "Покрасить качели и убрать мусор на детской площадке."},
    ];

    for (var task in tasks) {
      await firestore.collection('tasks').add({
        "title": task['title'],
        "description": task['description'],
        "status": "open",
        "createdAt": now,
      });
    }

    showSuccess("15 заданий успешно добавлены!");
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

      // Проверка: уже взята этим пользователем
      if (assignedList.contains(uid)) {
        throw Exception("Вы уже записаны на это задание");
      }

      // Проверка: свободные места
      if (assignedList.length >= maxPeople) {
        throw Exception("Мест больше нет");
      }

      // Добавляем текущего пользователя
      assignedList.add(uid);

      // Определяем новый статус
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
            icon: const Icon(Icons.add),
            onPressed: addSampleTasks,
            tooltip: "Добавить задания",
          ),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'FAQ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чат'),
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


