import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> notificationSettings = {
    'عروض وخصومات': true,
    'تحديثات الطلبات': true,
    'تنبيهات التطبيق': false,
    'رسائل الدعم': false,
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'الإشعارات',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (user == null)
                    const Center(child: Text('يجب تسجيل الدخول لعرض الإشعارات'))
                  else
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('notifications')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('لا توجد إشعارات بعد'));
                          }
                          final notifications = snapshot.data!.docs;
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final notif = notifications[i].data() as Map<String, dynamic>;
                              final title = notif['title'] ?? '';
                              final body = notif['body'] ?? '';
                              final timestamp = notif['timestamp'] as Timestamp?;
                              final date = timestamp != null ? timestamp.toDate() : null;
                              return ListTile(
                                title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(body, style: const TextStyle(fontSize: 15)),
                                    if (date != null)
                                      Text(
                                        '${date.year}/${date.month}/${date.day} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                leading: const Icon(Icons.notifications, color: Colors.orange),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 