import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizerTaskDetailsPage extends StatelessWidget {
  final Map<String, dynamic> taskData;

  const OrganizerTaskDetailsPage({super.key, required this.taskData});

  Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange;
      case 'pending_review':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_progress':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String translateStatus(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'pending_review':
        return 'На проверке';
      case 'completed':
        return 'Выполнено';
      case 'rejected':
        return 'Отклонено';
      case 'in_progress':
        return 'В процессе';
      default:
        return status;
    }
  }

  String formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    }
    return 'Не указано';
  }

  @override
  Widget build(BuildContext context) {
    final assigned = (taskData['assignedToList'] as List?)?.length ?? 0;
    final maxPeople = taskData['maxPeople']?.toString() ?? '0';
    final status = taskData['status'] ?? 'active';

    final title = taskData['title'] ?? 'Без названия';
    final location = taskData['location'] ?? 'Не указано';
    final description = taskData['description'] ?? 'Нет описания';
    final services = taskData['services'] ?? '-';

    final estimatedDuration =
        taskData['estimatedDuration'] != null
            ? '${taskData['estimatedDuration']} ч.'
            : 'Не указано';

    final eventTime = formatDate(taskData['eventTime']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Детали заявки"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        translateStatus(status),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.teal),
                        const SizedBox(width: 4),
                        Text('$assigned / $maxPeople'),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),
                _buildInfoRow("Локация:", location),
                _buildInfoRow("Дата и время:", eventTime),
                _buildInfoRow("Описание:", description),
                _buildInfoRow("Примерная длительность:", estimatedDuration),
                _buildInfoRow("Необходимые сервисы:", services),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
        const SizedBox(height: 12),
      ],
    );
  }
}
