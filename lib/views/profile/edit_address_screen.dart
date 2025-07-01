import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/components/Button.dart';

class EditAddressScreen extends StatefulWidget {
  final String? initialName;
  final String? initialAddress;
  final String? initialPhone;
  const EditAddressScreen({super.key, this.initialName, this.initialAddress, this.initialPhone});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? 'المنزل');
    addressController = TextEditingController(text: widget.initialAddress ?? 'القاهرة الكبرى، الجيزة، الهرم، شارع الملك فيصل، عمارة 12');
    phoneController = TextEditingController(text: widget.initialPhone ?? '01020304050');
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'تعديل العنوان',
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
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _EditField(
                            label: 'اسم العنوان',
                            controller: nameController,
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 28),
                          _EditField(
                            label: 'العنوان التفصيلي',
                            controller: addressController,
                            icon: Icons.home,
                          ),
                          const SizedBox(height: 28),
                          _EditField(
                            label: 'رقم الهاتف',
                            controller: phoneController,
                            icon: Icons.phone,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: Button(
                              onPressed: () {
                                // Save action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حفظ العنوان')),
                                );
                                Navigator.of(context).pop();
                              },
                              buttonContent: const Text(
                                'حفظ العنوان',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              buttonColor: AppColors.orangeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _EditField({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(icon, color: Colors.black, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 