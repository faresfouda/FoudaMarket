import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

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

  List<DocumentSnapshot> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (refresh) {
      setState(() {
        _notifications = [];
        _hasMore = true;
        _lastDoc = null;
        _isLoading = true;
      });
    } else {
      setState(() {
        _isLoading = _notifications.isEmpty;
      });
    }
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final querySnapshot = await query.get();
      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = querySnapshot.docs;
          } else {
            _notifications.addAll(querySnapshot.docs);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = querySnapshot.docs.length == _pageSize;
          if (querySnapshot.docs.isNotEmpty) {
            _lastDoc = querySnapshot.docs.last;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _loadNotifications();
  }

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
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                          size: 26,
                        ),
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
                  else if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_notifications.isEmpty)
                    const Expanded(
                      child: Center(child: Text('لا توجد إشعارات بعد')),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadNotifications(refresh: true),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount:
                              _notifications.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            if (i == _notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final notif =
                                _notifications[i].data()
                                    as Map<String, dynamic>;
                            final title = notif['title'] ?? '';
                            final body = notif['body'] ?? '';
                            final timestamp = notif['timestamp'] as Timestamp?;
                            final date = timestamp?.toDate();
                            return ListTile(
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    body,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.year}/${date.month}/${date.day} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              leading: const Icon(
                                Icons.notifications,
                                color: Colors.orange,
                              ),
                            );
                          },
                        ),
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
