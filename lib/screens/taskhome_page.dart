import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/helpers.dart';
import 'task_details_card.dart';

class TaskHomeScreen extends StatefulWidget {
  final DocumentSnapshot task;

  const TaskHomeScreen({super.key, required this.task});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  LatLng? selectedLatLng;

  @override
  void initState() {
    super.initState();
    final data = widget.task.data() as Map<String, dynamic>;
    if (data['lat'] != null && data['lng'] != null) {
      selectedLatLng = LatLng(data['lat'], data['lng']);
    }
  }

  Future<void> _takeTask(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.task.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("Задание не найдено");

        final activeTasksQuery =
            await FirebaseFirestore.instance
                .collection('tasks')
                .where('assignedToList', arrayContains: uid)
                .where('status', whereIn: ['open', 'in_progress'])
                .get();

        if (activeTasksQuery.docs.isNotEmpty) {
          throw Exception(
            "Нельзя участвовать более чем в одном активном задании",
          );
        }

        final data = snapshot.data()!;
        final assignedList = List<String>.from(data['assignedToList'] ?? []);
        final maxPeople = data['maxPeople'] ?? 200;

        if (assignedList.contains(uid))
          throw Exception("Вы уже участвуете в этом задании");
        if (assignedList.length >= maxPeople)
          throw Exception("Мест больше нет");

        assignedList.add(uid);

        transaction.update(docRef, {
          'assignedToList': assignedList,
          'status': 'in_progress',
        });
      });

      showSuccess("Вы успешно записались на задание!");
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      showError("Ошибка при записи: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.task.data() as Map<String, dynamic>;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final assignedList = List<String>.from(data['assignedToList'] ?? []);
    final maxPeople = data['maxPeople'] ?? 200;

    final canTakeTask =
        (data['status'] == 'open' || data['status'] == 'in_progress') &&
        !assignedList.contains(currentUid) &&
        assignedList.length < maxPeople;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали задания')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: TaskDetailsCard(
                data: data,
                selectedLatLng: selectedLatLng,
              ),
            ),
          ),
          if (canTakeTask)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _takeTask(context),
                child: const Text("Взять в работу"),
              ),
            ),
        ],
      ),
    );
  }
}
