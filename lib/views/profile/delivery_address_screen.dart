import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/views/profile/edit_address_screen.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../models/address_model.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      context.read<AddressBloc>().add(LoadAddresses(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.orange,
        body: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.orange,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  // AppBar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
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
                            'عناوين التوصيل',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Expanded(
                    child: BlocConsumer<AddressBloc, AddressState>(
                      listener: (context, state) {
                        setState(() {
                          _isLoading = false;
                        });

                        if (state is AddressOperationSuccess) {
                          _loadAddresses();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تنفيذ العملية بنجاح'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (state is AddressesError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (_isLoading || state is AddressesLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        }

                        if (state is AddressesLoaded) {
                          final addresses = state.addresses;

                          if (addresses.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 64,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد عناوين محفوظة',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'أضف عنوان التوصيل الأول',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              _loadAddresses();
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                bottom: 100, // Space for FAB
                                left: 16,
                                right: 16,
                                top: 8,
                              ),
                              itemCount: addresses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final address = addresses[index];
                                return _buildAddressCard(address);
                              },
                            ));
                        }

                        if (state is AddressesError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'حدث خطأ في تحميل العناوين',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadAddresses,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Floating Action Button
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: BlocProvider.of<AddressBloc>(context),
                            child: const EditAddressScreen(),
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadAddresses();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'إضافة عنوان جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: address.isDefault
            ? Border.all(color: Colors.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                address.isDefault ? Icons.star : Icons.location_on,
                color: address.isDefault ? Colors.orange : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.name.isNotEmpty ? address.name : 'عنوان غير محدد',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address.isDefault)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'العنوان الافتراضي',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!address.isDefault)
                    IconButton(
                      icon: const Icon(
                        Icons.star_border,
                        color: Colors.orange,
                        size: 20,
                      ),
                      onPressed: () => _setDefaultAddress(address),
                      tooltip: 'جعل افتراضي',
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () => _editAddress(address),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(address),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Address details
          if (address.address.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_outlined,
                  color: Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Phone number
          if (address.phone.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  address.phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _setDefaultAddress(AddressModel address) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<AddressBloc>().add(
        SetDefaultAddress(user.uid, address.id),
      );
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: BlocProvider.of<AddressBloc>(context),
          child: EditAddressScreen(
            initialName: address.name,
            initialAddress: address.address,
            initialPhone: address.phone,
            addressId: address.id,
            initialIsDefault: address.isDefault,
          ),
        ),
      ),
    );
    if (result == true) {
      _loadAddresses();
    }
  }

  void _showDeleteDialog(AddressModel address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف العنوان',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف "${address.name}"؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  context.read<AddressBloc>().add(DeleteAddress(address.id, user.uid));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}
