import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      "question": "Как стать волонтёром?",
      "answer":
          "Просто зарегистрируйтесь в приложении, выберите задание и нажмите «Взять в работу». После выполнения задания отметьте его как завершённое."
    },
    {
      "question": "Нужно ли проходить обучение?",
      "answer":
          "Нет, большинство заданий не требуют специальной подготовки. Однако внимательно читайте описание перед принятием задания."
    },
    {
      "question": "Можно ли отказаться от задания?",
      "answer":
          "Да, если не можете выполнить задание, сообщите администратору или просто не выполняйте его — оно вернётся в список доступных."
    },
    {
      "question": "Как связаться с организатором задания?",
      "answer":
          "Контактная информация может быть указана в описании задания. В будущем мы планируем добавить чат внутри приложения."
    },
    {
      "question": "Что делать после выполнения задания?",
      "answer":
          "Откройте своё задание в профиле и нажмите кнопку «Завершить», если такая имеется, или подождите подтверждения от организатора."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Часто задаваемые вопросы'),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              collapsedIconColor: Colors.teal,
              iconColor: Colors.teal,
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
