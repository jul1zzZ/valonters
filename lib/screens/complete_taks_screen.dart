import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompleteTaskScreen extends StatefulWidget {
  final String taskId;

  const CompleteTaskScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  File? _image;
  bool _loading = false;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Прикрепите фото!')));
      return;
    }

    setState(() => _loading = true);

    final bytes = await _image!.readAsBytes();
    final base64Image = base64Encode(bytes);

    await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
      'completionPhoto': base64Image,
      'status': 'pending_review',
    });

    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Подтверждение выполнения')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text('Пожалуйста, загрузите фотоотчёт для подтверждения выполнения задания.'),
                  SizedBox(height: 20),
                  _image != null
                      ? Image.file(_image!, height: 200)
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(child: Text('Нет изображения')),
                        ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text('Выбрать фото'),
                    onPressed: _pickImage,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text('Отправить на проверку'),
                  )
                ],
              ),
      ),
    );
  }
}
