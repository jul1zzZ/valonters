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
  void editTaskDialog(DocumentSnapshot task) {
    final titleController = TextEditingController(
      text: (task['title'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (task['description'] ?? '').toString(),
    );
    final categoryController = TextEditingController(
      text: (task['category'] ?? '').toString(),
    );
    final locationController = TextEditingController(
      text: (task['location'] ?? '').toString(),
    );
    final durationController = TextEditingController(
      text: (task['estimatedDuration'] ?? '').toString(),
    );
    final servicesController = TextEditingController(
      text: (task['services'] ?? '').toString(),
    );
    final maxPeopleController = TextEditingController(
      text: (task['maxPeople'] ?? '').toString(),
    );

    DateTime selectedDateTime;
    try {
      selectedDateTime = (task['eventTime'] as Timestamp).toDate();
    } catch (e) {
      selectedDateTime = DateTime.now();
    }

    double lat = 0.0;
    double lng = 0.0;
    try {
      lat =
          (task['lat'] is double)
              ? task['lat']
              : double.parse(task['lat'].toString());
      lng =
          (task['lng'] is double)
              ? task['lng']
              : double.parse(task['lng'].toString());
    } catch (e) {
      lat = 0.0;
      lng = 0.0;
    }
    LatLng selectedLatLng = LatLng(lat, lng);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Редактировать заявку"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _styledTextField(titleController, "Название"),
                        _styledTextField(descriptionController, "Описание"),
                        _styledTextField(categoryController, "Категория"),
                        _styledTextField(locationController, "Адрес/локация"),
                        _styledTextField(durationController, "Длительность"),
                        _styledTextField(servicesController, "Сервисы"),
                        _styledTextField(
                          maxPeopleController,
                          "Макс. кол-во участников",
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text("Дата и время: "),
                            TextButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      selectedDateTime.isBefore(now)
                                          ? now
                                          : selectedDateTime,
                                  firstDate: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  ),
                                  lastDate: DateTime(2100),
                                );

                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      selectedDateTime,
                                    ),
                                  );
                                  if (time != null) {
                                    final chosenDateTime = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );

                                    if (chosenDateTime.isBefore(now)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Нельзя выбрать время в прошлом',
                                          ),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        selectedDateTime = chosenDateTime;
                                      });
                                    }
                                  }
                                }
                              },
                              child: Text(
                                DateFormat(
                                  'dd.MM.yyyy HH:mm',
                                ).format(selectedDateTime),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text("Координаты на карте:"),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: selectedLatLng,
                              initialZoom: 13,
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
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: selectedLatLng,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      size: 40,
                                      color: Colors.red,
                                    ),
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
                        try {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(task.id)
                              .update({
                                'title': titleController.text.trim(),
                                'description':
                                    descriptionController.text.trim(),
                                'category': categoryController.text.trim(),
                                'location': locationController.text.trim(),
                                'estimatedDuration':
                                    durationController.text.trim(),
                                'services': servicesController.text.trim(),
                                'maxPeople':
                                    int.tryParse(
                                      maxPeopleController.text.trim(),
                                    ) ??
                                    1,
                                'eventTime': Timestamp.fromDate(
                                  selectedDateTime,
                                ),
                                'lat': selectedLatLng.latitude,
                                'lng': selectedLatLng.longitude,
                              });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Заявка обновлена')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
                        }
                      },
                      child: const Text("Сохранить"),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Заявка удалена")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление заявками"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) return const Center(child: Text("Заявок нет"));

          return ListView.builder(
            itemCount: tasks.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final createdAt = (task['createdAt'] as Timestamp).toDate();
              final formattedDate = DateFormat(
                'dd.MM.yyyy HH:mm',
              ).format(createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ExpansionTile(
                  title: Text(
                    task['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${task['description']}\nСоздано: $formattedDate',
                  ),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    Text('Категория: ${task['category']}'),
                    Text('Адрес: ${task['location']}'),
                    Text('Длительность: ${task['estimatedDuration']}'),
                    Text('Сервисы: ${task['services']}'),
                    Text('Макс. участников: ${task['maxPeople']}'),
                    Text(
                      'Дата и время: ${DateFormat('dd.MM.yyyy HH:mm').format((task['eventTime'] as Timestamp).toDate())}',
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<DocumentSnapshot>>(
                      future: _getAssignedUsers(task['assignedToList'] ?? []),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasData &&
                            snapshot.data!.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Волонтёры:'),
                              ...snapshot.data!.map(
                                (user) => Text(
                                  '- ${user['name']} (${user['email']})',
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const Text('Волонтёров нет');
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => editTaskDialog(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteTask(task.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _getAssignedUsers(List<dynamic> ids) async {
    if (ids.isEmpty) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: ids)
            .get();
    return snapshot.docs;
  }
}
