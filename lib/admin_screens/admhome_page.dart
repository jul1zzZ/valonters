import 'package:flutter/material.dart';
import 'admin_tasks_page.dart';
import 'admin_users_page.dart';
import 'admin_blocked_users_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:valonters/screens/login_page.dart';
import 'admin_support_list_page.dart';
import 'package:valonters/admin_screens/admin_photo_review_page.dart';
import 'stats_screen.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminPhotoReviewScreen(), // Фотоотчёты — главная
    const AdminTasksPage(),
    const AdminUsersPage(),
    const AdminBlockedUsersPage(),
    const AdminSupportListPage(),
    VolunteerStatsScreen(), // Добавили статистику волонтеров
  ];

  final List<String> _titles = [
    'Проверка фотоотчетов',
    'Заявки',
    'Пользователи',
    'Заблокированные',
    'Поддержка',
    'Статистика волонтеров', // Заголовок для новой страницы
  ];

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Админ-панель — ${_titles[_selectedIndex]}',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: () => _logout(context),
            color: theme.appBarTheme.foregroundColor,
          ),
        ],
        elevation: theme.appBarTheme.elevation,
        centerTitle: theme.appBarTheme.centerTitle,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.disabledColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Фотоотчёты'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.block), label: 'Баны'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Поддержка'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ), // Новый пункт
        ],
      ),
    );
  }
}
