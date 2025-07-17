import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';

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
              onPressed: () {
                // Implement send logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال الإشعار!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
