import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/address/address_state.dart';
import 'package:fouda_market/blocs/address/address_event.dart';

/// Widget لإدارة اختيار وعرض العناوين
class AddressSelector {
  /// عرض مربع حوار اختيار العنوان
  static Future<void> showAddressSelectionDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // أرسل حدث تحميل العناوين عند فتح الـ bottom sheet
    context.read<AddressBloc>().add(LoadAddresses(user.uid));

    await showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressSelectionBottomSheet(),
    );

    // بعد إغلاق الـ bottom sheet، أعد تحميل العنوان الافتراضي
    context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
  }
}

/// Widget للـ Bottom Sheet الخاص باختيار العنوان
class _AddressSelectionBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandleBar(),
          _buildHeader(context),
          Expanded(child: _buildAddressList(context)),
          _buildAddNewAddressButton(context),
        ],
      ),
    );
  }

  /// بناء شريط السحب العلوي
  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// بناء عنوان الحوار
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'اختر عنوان التوصيل',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة العناوين
  Widget _buildAddressList(BuildContext context) {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        if (state is AddressesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AddressesLoaded) {
          final addresses = state.addresses;
          if (addresses.isEmpty) {
            return _buildEmptyAddresses(context);
          }
          return _buildAddressListView(context, addresses);
        } else if (state is AddressesError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  /// بناء حالة عدم وجود عناوين
  Widget _buildEmptyAddresses(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عناوين',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToAddAddress(context),
            child: const Text('إضافة عنوان جديد'),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة العناوين
  Widget _buildAddressListView(BuildContext context, List addresses) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              address.isDefault ? Icons.star : Icons.location_on,
              color: address.isDefault ? Colors.orange : Colors.grey,
            ),
            title: Text(
              address.name,
              style: TextStyle(
                fontWeight: address.isDefault
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.address),
                if (address.isDefault)
                  Text(
                    'العنوان الافتراضي',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: address.isDefault
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              if (!address.isDefault && user != null) {
                context.read<AddressBloc>().add(
                  SetDefaultAddress(user.uid, address.id),
                );
              }
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  /// بناء زر إضافة عنوان جديد
  Widget _buildAddNewAddressButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _navigateToAddAddress(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'إضافة عنوان جديد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// التنقل إلى صفحة إضافة العنوان
  Future<void> _navigateToAddAddress(BuildContext context) async {
    Navigator.pop(context);
    // تأخير قصير لتجنب مشاكل دورة حياة Widget
    await Future.delayed(Duration(milliseconds: 100));

    // التحقق من أن Widget لا يزال موجوداً
    if (!context.mounted) return;

    try {
      final result = await Navigator.pushNamed(
        context,
        '/delivery-address',
      );

      // التحقق من أن Widget لا يزال موجوداً قبل استخدام context
      if (!context.mounted) return;

      // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
      if (result == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && context.mounted) {
          // إعادة تحميل العنوان الافتراضي
          context.read<AddressBloc>().add(
            LoadDefaultAddress(user.uid),
          );
        }
      }
    } catch (e) {
      print('[DEBUG] Error navigating to delivery-address: $e');
      // محاولة بديلة باستخدام Navigator.of(context, rootNavigator: true)
      if (!context.mounted) return;
      try {
        final result = await Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed('/delivery-address');
        if (!context.mounted) return;
        if (result == true) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && context.mounted) {
            context.read<AddressBloc>().add(
              LoadDefaultAddress(user.uid),
            );
          }
        }
      } catch (e2) {
        print('[DEBUG] Alternative navigation also failed: $e2');
      }
    }
  }
}
