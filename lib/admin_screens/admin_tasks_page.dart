import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminTasksPage extends StatefulWidget {
  const AdminTasksPage({super.key});

  @override
  State<AdminTasksPage> createState() => _AdminTasksPageState();
}

class _AdminTasksPageState extends State<AdminTasksPage> {
  void addTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    final servicesController = TextEditingController();
    final photoUrlController = TextEditingController();

    DateTime? selectedDateTime;
    LatLng? selectedLatLng;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Добавить заявку"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Название"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Описание"),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: "Длительность"),
                ),
                TextField(
                  controller: servicesController,
                  decoration: const InputDecoration(labelText: "Сервисы"),
                ),
                TextField(
                  controller: photoUrlController,
                  decoration: const InputDecoration(labelText: "URL фото"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("Дата и время: "),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        selectedDateTime == null
                            ? "Выбрать"
                            : "${selectedDateTime!.toLocal()}".split('.')[0],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Выберите точку на карте:"),
                SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(55.751244, 37.618423),
                      initialZoom: 12,
                      onTap: (tapPosition, latLng) {
                        setState(() {
                          selectedLatLng = latLng;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      if (selectedLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selectedLatLng!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin,
                                  size: 40, color: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedLatLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Пожалуйста, выберите точку на карте"),
                    ),
                  );
                  return;
                }
                if (selectedDateTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Пожалуйста, выберите дату и время"),
                    ),
                  );
                  return;
                }
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Введите название заявки"),
                    ),
                  );
                  return;
                }
                // Можно добавить проверки для других полей, если нужно

                try {
                  await FirebaseFirestore.instance.collection('tasks').add({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'estimatedDuration': durationController.text.trim(),
                    'services': servicesController.text.trim(),
                    'photoUrl': photoUrlController.text.trim(),
                    'eventTime': Timestamp.fromDate(selectedDateTime!),
                    'location':
                        '${selectedLatLng!.latitude},${selectedLatLng!.longitude}',
                    'status': 'open',
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Ошибка при добавлении заявки: $e"),
                    ),
                  );
                }
              },
              child: const Text("Добавить"),
            ),
          ],
        ),
      ),
    );
  }

  void deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Заявка удалена")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление заявками"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addTaskDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(child: Text("Заявок нет"));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task['title']),
                subtitle: Text(task['description']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteTask(task.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
