import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendNotificationScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  SendNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعار للعملاء'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الإشعار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'محتوى الإشعار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Button(
              buttonContent: const Text(
                'إرسال',
                style: TextStyle(color: Colors.white),
              ),
              buttonColor: AppColors.orangeColor,
              onPressed: () async {
                final title = titleController.text.trim();
                final body = messageController.text.trim();

                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال عنوان ومحتوى الإشعار')),
                  );
                  return;
                }

                try {
                  // جلب جميع توكنات المستخدمين من Firestore
                  final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
                  final tokens = usersSnapshot.docs
                      .map((doc) => doc.data()['fcmToken'])
                      .where((token) => token != null && token.isNotEmpty)
                      .toList();

                  if (tokens.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا يوجد مستخدمين لديهم FCM Token')),
                    );
                    return;
                  }

                  // إرسال الطلب إلى Vercel API
                  final response = await http.post(
                    Uri.parse('https://fcm-api-seven.vercel.app/api/send-fcm'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'fcmTokens': tokens,
                      'title': title,
                      'body': body,
                    }),
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال الإشعار لجميع المستخدمين!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في إرسال الإشعار: \n${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
