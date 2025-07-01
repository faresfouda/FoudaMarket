import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> helpTopics = [
    'كيفية الطلب من التطبيق',
    'طرق الدفع المتاحة',
    'سياسة الاسترجاع',
    'مواعيد التوصيل',
    'التواصل مع الدعم',
  ];
  final List<Map<String, String>> chatMessages = [
    {'from': 'support', 'msg': 'مرحباً! كيف يمكنني مساعدتك؟'},
    {'from': 'user', 'msg': 'كيف أتابع طلبي؟'},
    {'from': 'support', 'msg': 'يمكنك متابعة الطلب من صفحة "طلباتي".'},
  ];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // void _sendMessage() {
  //   if (_chatController.text.trim().isNotEmpty) {
  //     setState(() {
  //       chatMessages.add({'from': 'user', 'msg': _chatController.text.trim()});
  //       _chatController.clear();
  //     });
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       _scrollController.animateTo(
  //         _scrollController.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOut,
  //       );
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'مساعدة',
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
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.orange,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      Tab(text: 'الدليل'),
                      Tab(text: 'الدردشة'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Guide Tab
                        ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: helpTopics.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) => ListTile(
                            leading: const Icon(Icons.help_outline, color: Colors.orange),
                            title: Text(helpTopics[i], style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        // Chat Tab
                        Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: chatMessages.length,
                                itemBuilder: (context, i) {
                                  final msg = chatMessages[i];
                                  final isUser = msg['from'] == 'user';
                                  return Row(
                                    mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isUser)
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.orange,
                                          child: Icon(Icons.support_agent, color: Colors.white, size: 20),
                                        ),
                                      if (!isUser) const SizedBox(width: 8),
                                      Flexible(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isUser ? Colors.orange[50] : Colors.grey[200],
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                                              bottomRight: Radius.circular(isUser ? 4 : 16),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(msg['msg']!, style: const TextStyle(fontSize: 16)),
                                        ),
                                      ),
                                      if (isUser) const SizedBox(width: 8),
                                      if (isUser)
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.person, color: Colors.white, size: 20),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _chatController,
                                      decoration: const InputDecoration(
                                        hintText: 'اكتب رسالتك...',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.orange),
                                    onPressed: () {
                                      if (_chatController.text.trim().isNotEmpty) {
                                        setState(() {
                                          chatMessages.add({'from': 'user', 'msg': _chatController.text.trim()});
                                          _chatController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
} 