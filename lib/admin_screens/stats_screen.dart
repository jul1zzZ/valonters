import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VolunteerStatsScreen extends StatefulWidget {
  const VolunteerStatsScreen({super.key});

  @override
  _VolunteerStatsScreenState createState() => _VolunteerStatsScreenState();
}

class _VolunteerStatsScreenState extends State<VolunteerStatsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, double> _hoursByVolunteer = {};
  bool _loading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          _startDate = newDate;
        } else {
          _endDate = newDate;
        }
      });
    }
  }

  Future<void> _loadStats() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите начальную и конечную даты'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _hoursByVolunteer.clear();
    });

    try {
      print('Загрузка заявок с ${_startDate!} по ${_endDate!}...');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where(
                'eventTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
              )
              .where(
                'eventTime',
                isLessThanOrEqualTo: Timestamp.fromDate(_endDate!),
              )
              .get();

      print('Найдено заявок: ${snapshot.docs.length}');

      final Map<String, double> uidToHours = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docId = doc.id;
        final assignedList = List<String>.from(data['assignedToList'] ?? []);
        final duration =
            (data['estimatedDuration'] is num)
                ? (data['estimatedDuration'] as num).toDouble()
                : 0.0;

        print('Заявка: $docId, duration: $duration, assignedTo: $assignedList');

        for (final uid in assignedList) {
          uidToHours[uid] = (uidToHours[uid] ?? 0) + duration;
          print('Добавлено $duration ч. пользователю $uid');
        }
      }

      final userDocs =
          await FirebaseFirestore.instance.collection('users').get();
      final Map<String, String> uidToName = {};
      for (final doc in userDocs.docs) {
        final name = doc.data()['name'] ?? 'Без имени';
        uidToName[doc.id] = name;
      }

      final Map<String, double> nameToHours = {};
      uidToHours.forEach((uid, hours) {
        final name = uidToName[uid] ?? 'Неизвестный ($uid)';
        nameToHours[name] = hours;
        print('Итог: $name — $hours ч.');
      });

      setState(() {
        _hoursByVolunteer = nameToHours;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Ошибка загрузки статистики: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки статистики: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика волонтеров')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      _startDate == null
                          ? 'Выбрать дату начала'
                          : 'Начало: ${_startDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      _endDate == null
                          ? 'Выбрать дату конца'
                          : 'Конец: ${_endDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _loadStats,
              child: const Text('Показать статистику'),
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                  child:
                      _hoursByVolunteer.isEmpty
                          ? const Text('Нет данных для выбранного периода')
                          : ListView(
                            children:
                                _hoursByVolunteer.entries
                                    .map(
                                      (e) => ListTile(
                                        title: Text('Пользователь: ${e.key}'),
                                        subtitle: Text(
                                          'Отработано часов: ${e.value.toStringAsFixed(2)}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                ),
          ],
        ),
      ),
    );
  }
}
