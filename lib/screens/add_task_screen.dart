import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class AddTaskPage extends StatefulWidget {
  final String userId;
  final DocumentSnapshot? taskDoc;

  const AddTaskPage({super.key, required this.userId, this.taskDoc});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '', description = '', category = '', location = '';
  double estimatedDuration = 1.0;
  String services = '';
  DateTime? eventTime;
  int maxPeople = 1;
  LatLng? markerPos;

  @override
  void initState() {
    super.initState();
    if (widget.taskDoc != null) {
      final data = widget.taskDoc!.data() as Map<String, dynamic>;
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      category = data['category'] ?? '';
      location = data['location'] ?? '';

      final rawDuration = data['estimatedDuration'] ?? 1.0;
      if (rawDuration is num) {
        estimatedDuration = rawDuration.toDouble();
      } else if (rawDuration is String) {
        estimatedDuration = double.tryParse(rawDuration) ?? 1.0;
      } else {
        estimatedDuration = 1.0;
      }

      services = data['services'] ?? '';
      eventTime = (data['eventTime'] as Timestamp).toDate();
      maxPeople = data['maxPeople'] ?? 1;
      markerPos = LatLng(data['lat'], data['lng']);
    }
  }

  void saveTask() async {
    if (_formKey.currentState!.validate() &&
        markerPos != null &&
        eventTime != null) {
      final taskData = {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'estimatedDuration': estimatedDuration,
        'services': services,
        'eventTime': Timestamp.fromDate(eventTime!),
        'maxPeople': maxPeople,
        'lat': markerPos!.latitude,
        'lng': markerPos!.longitude,
      };

      if (widget.taskDoc != null) {
        await widget.taskDoc!.reference.update(taskData);
      } else {
        await FirebaseFirestore.instance.collection('tasks').add({
          ...taskData,
          'assignedToList': [],
          'createdBy': widget.userId,
          'createdAt': Timestamp.now(),
          'status': 'open',
          'completedAt': null,
        });
      }

      Navigator.pop(context);
    }
  }

  Future<void> pickEventDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: eventTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          eventTime != null
              ? TimeOfDay.fromDateTime(eventTime!)
              : const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Нельзя выбрать время в прошлом")),
      );
      return;
    }

    setState(() {
      eventTime = selectedDateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskDoc != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Редактировать заявку" : "Новая заявка"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: "Заголовок"),
                onChanged: (v) => title = v,
                validator: (v) => v!.isEmpty ? "Введите заголовок" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: "Описание"),
                onChanged: (v) => description = v,
                validator: (v) => v!.isEmpty ? "Введите описание" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: category,
                decoration: const InputDecoration(labelText: "Категория"),
                onChanged: (v) => category = v,
                validator: (v) => v!.isEmpty ? "Введите категорию" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: location,
                decoration: const InputDecoration(
                  labelText: "Местоположение (адрес)",
                ),
                onChanged: (v) => location = v,
                validator: (v) => v!.isEmpty ? "Введите адрес" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: maxPeople.toString(),
                decoration: const InputDecoration(
                  labelText: "Макс. участников (1–200)",
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => maxPeople = int.tryParse(v) ?? 1,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 200) {
                    return "Введите число от 1 до 200";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: estimatedDuration.toString(),
                decoration: const InputDecoration(
                  labelText: "Примерная длительность (в часах)",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged:
                    (v) =>
                        estimatedDuration =
                            double.tryParse(v.replaceAll(',', '.')) ?? 1.0,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Введите длительность";
                  final value = double.tryParse(v.replaceAll(',', '.'));
                  if (value == null) return "Введите корректное число";
                  if (value <= 0) return "Длительность должна быть больше 0";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: services,
                decoration: const InputDecoration(
                  labelText: "Необходимые сервисы (через запятую)",
                ),
                onChanged: (v) => services = v,
                validator: (v) => v!.isEmpty ? "Введите сервисы" : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eventTime != null
                          ? "Дата и время: ${eventTime!.toLocal().toString().substring(0, 16)}"
                          : "Не выбрано время проведения",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: pickEventDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Выберите точку на карте"),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: markerPos ?? LatLng(55.751244, 37.618423),
                    initialZoom: 12,
                    onTap: (tapPos, latlng) {
                      setState(() {
                        markerPos = latlng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (markerPos != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: markerPos!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveTask,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text(
                  isEditing ? "Сохранить изменения" : "Создать заявку",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
