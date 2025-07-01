import 'package:flutter/material.dart';
import 'package:fodamarket/views/profile/edit_address_screen.dart';

class DeliveryAddressScreen extends StatelessWidget {
  const DeliveryAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addresses = [
      {
        'name': 'المنزل',
        'address': 'القاهرة الكبرى، الجيزة، الهرم، شارع الملك فيصل، عمارة 12',
        'phone': '01020304050',
      },
      {
        'name': 'العمل',
        'address': 'مدينة نصر، شارع عباس العقاد، برج 5',
        'phone': '01111222333',
      },
      
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                // AppBar style title bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'عناوين التوصيل',
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
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, i) {
                      final address = addresses[i];
                      return Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.black, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  address['name']!,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.black, size: 22),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditAddressScreen(
                                          initialName: address['name'],
                                          initialAddress: address['address'],
                                          initialPhone: address['phone'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.home, color: Colors.black, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address['address']!,
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.black, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  address['phone']!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 