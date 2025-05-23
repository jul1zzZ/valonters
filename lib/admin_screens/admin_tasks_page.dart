import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Добавить заявку"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledTextField(titleController, "Название"),
                _styledTextField(descriptionController, "Описание"),
                _styledTextField(durationController, "Длительность"),
                _styledTextField(servicesController, "Сервисы"),
                _styledTextField(photoUrlController, "URL фото"),
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
                            : DateFormat('dd.MM.yyyy HH:mm').format(selectedDateTime!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Выберите точку на карте:"),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedLatLng == null || selectedDateTime == null || titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Пожалуйста, заполните все обязательные поля")),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('tasks').add({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'estimatedDuration': durationController.text.trim(),
                    'services': servicesController.text.trim(),
                    'photoUrl': photoUrlController.text.trim(),
                    'eventTime': Timestamp.fromDate(selectedDateTime!),
                    'location': '${selectedLatLng!.latitude},${selectedLatLng!.longitude}',
                    'status': 'open',
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ошибка: $e")),
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

  Widget _styledTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  void deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Заявка удалена")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление заявками"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) return const Center(child: Text("Заявок нет"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final createdAt = (task['createdAt'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    task['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('${task['description']}\nСоздано: $formattedDate'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTask(task.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
