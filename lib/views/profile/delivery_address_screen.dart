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
  @override
  void initState() {
    super.initState();
    // تحميل العناوين عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<AddressBloc>().add(LoadAddresses(user.uid));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('Current user in DeliveryAddressScreen: ' + user.toString());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<AddressBloc>(context),
                child: EditAddressScreen(),
              ),
            ),
          );
          
          // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
          if (result == true) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && mounted) {
              // إعادة تحميل العناوين والعنوان الافتراضي
              context.read<AddressBloc>().add(LoadAddresses(user.uid));
              context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
            }
          }
        },
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor: Colors.orange,
      ),
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
                  child: BlocBuilder<AddressBloc, AddressState>(
                    builder: (context, state) {
                      if (state is AddressesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is AddressesLoaded) {
                        final addresses = state.addresses;
                        if (addresses.isEmpty) {
                          return const Center(child: Text('لا توجد عناوين بعد'));
                        }
                        return ListView.separated(
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
                                border: address.isDefault 
                                    ? Border.all(color: Colors.orange, width: 2)
                                    : null,
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
                                      Icon(
                                        address.isDefault ? Icons.star : Icons.location_on, 
                                        color: address.isDefault ? Colors.orange : Colors.black, 
                                        size: 28
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              address.name,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            if (address.isDefault)
                                              Text(
                                                'العنوان الافتراضي',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!address.isDefault)
                                        IconButton(
                                          icon: const Icon(Icons.star_border, color: Colors.orange, size: 22),
                                          onPressed: () {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null) {
                                              context.read<AddressBloc>().add(SetDefaultAddress(user.uid, address.id));
                                            }
                                          },
                                          tooltip: 'اجعل افتراضي',
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.black, size: 22),
                                        onPressed: () async {
                                          await Navigator.push(
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
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                        onPressed: () {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user != null) {
                                            context.read<AddressBloc>().add(DeleteAddress(address.id, user.uid));
                                          }
                                        },
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
                                          address.address,
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
                                        address.phone,
                                        style: const TextStyle(fontSize: 16, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (state is AddressesError) {
                        return Center(child: Text(state.message));
                      } else {
                        return const SizedBox.shrink();
                      }
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