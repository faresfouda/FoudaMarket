import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/components/Button.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../models/address_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditAddressScreen extends StatefulWidget {
  final String? initialName;
  final String? initialAddress;
  final String? initialPhone;
  final String? addressId;
  final bool? initialIsDefault;
  const EditAddressScreen({
    super.key, 
    this.initialName, 
    this.initialAddress, 
    this.initialPhone, 
    this.addressId,
    this.initialIsDefault,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? 'المنزل');
    addressController = TextEditingController(text: widget.initialAddress ?? 'القاهرة الكبرى، الجيزة، الهرم، شارع الملك فيصل، عمارة 12');
    phoneController = TextEditingController(text: widget.initialPhone ?? '01020304050');
    isDefault = widget.initialIsDefault ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                          const SizedBox(height: 28),
                          // خيار العنوان الافتراضي
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: isDefault ? Colors.orange : Colors.grey[400], size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'اجعل هذا العنوان افتراضيًا',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isDefault ? Colors.orange : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'سيتم استخدام هذا العنوان تلقائيًا في الطلبات',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      isDefault = value;
                                    });
                                  },
                                  activeColor: AppColors.orangeColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Builder(
                            builder: (context) => SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: Button(
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) return;
                                  final address = AddressModel(
                                    id: widget.addressId ?? '',
                                    userId: user.uid,
                                    name: nameController.text,
                                    address: addressController.text,
                                    phone: phoneController.text,
                                    isDefault: isDefault,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  
                                  if (widget.addressId == null) {
                                    context.read<AddressBloc>().add(AddAddress(address));
                                  } else {
                                    context.read<AddressBloc>().add(UpdateAddress(address));
                                  }
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(widget.addressId == null ? 'تم إضافة العنوان' : 'تم تحديث العنوان')),
                                  );
                                  
                                  // إرجاع true لإعلام الشاشة الأم أن هناك تغييراً
                                  Navigator.of(context).pop(true);
                                },
                                buttonContent: const Text(
                                  'حفظ العنوان',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                buttonColor: AppColors.orangeColor,
                              ),
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