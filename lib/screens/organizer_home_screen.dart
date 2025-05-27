import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganizerHomePage extends StatelessWidget {
  final String userId;

  const OrganizerHomePage({super.key, required this.userId});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance.collection('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Мои заявки"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksRef.where('createdBy', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final assignedCount = (data['assignedToList'] as List?)?.length ?? 0;
            final max = data['maxPeople'] ?? 200;
            final status = data['status'] ?? '';
            return status != 'done' && assignedCount < max;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("Нет активных заявок"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['location'] ?? ''),
                trailing: Text('${(data['assignedToList']?.length ?? 0)}/${data['maxPeople']}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/addTask', arguments: userId),
      ),
    );
  }
}
