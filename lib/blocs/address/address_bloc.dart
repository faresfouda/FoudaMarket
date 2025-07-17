import 'package:flutter_bloc/flutter_bloc.dart';
import 'address_event.dart';
import 'address_state.dart';
import '../../core/services/address_service.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressService _addressService = AddressService();
  AddressBloc() : super(AddressesLoading()) {
    on<LoadAddresses>((event, emit) async {
      emit(AddressesLoading());
      try {
        final addresses = await _addressService.getUserAddresses(event.userId);
        emit(AddressesLoaded(addresses));
      } catch (e) {
        print('AddressBloc error: $e');
        emit(AddressesError('فشل في تحميل العناوين'));
      }
    });

    on<LoadDefaultAddress>((event, emit) async {
      emit(DefaultAddressLoading());
      try {
        final defaultAddress = await _addressService.getDefaultAddress(event.userId);
        emit(DefaultAddressLoaded(defaultAddress));
      } catch (e) {
        print('AddressBloc LoadDefaultAddress error: $e');
        emit(DefaultAddressError('فشل في تحميل العنوان الافتراضي'));
      }
    });

    on<AddAddress>((event, emit) async {
      try {
        await _addressService.addAddress(event.address);
        emit(AddressOperationSuccess());
        // إعادة تحميل العناوين بعد الإضافة
        final addresses = await _addressService.getUserAddresses(event.address.userId);
        emit(AddressesLoaded(addresses));
        // تحميل العنوان الافتراضي بعد الإضافة
        final defaultAddress = await _addressService.getDefaultAddress(event.address.userId);
        emit(DefaultAddressLoaded(defaultAddress));
      } catch (e) {
        emit(AddressesError('فشل في إضافة العنوان'));
      }
    });

    on<UpdateAddress>((event, emit) async {
      try {
        await _addressService.updateAddress(event.address);
        emit(AddressOperationSuccess());
        // إعادة تحميل العناوين بعد التحديث
        final addresses = await _addressService.getUserAddresses(event.address.userId);
        emit(AddressesLoaded(addresses));
        // تحميل العنوان الافتراضي بعد التحديث
        final defaultAddress = await _addressService.getDefaultAddress(event.address.userId);
        emit(DefaultAddressLoaded(defaultAddress));
      } catch (e) {
        emit(AddressesError('فشل في تحديث العنوان'));
      }
    });

    on<DeleteAddress>((event, emit) async {
      try {
        await _addressService.deleteAddress(event.addressId);
        emit(AddressOperationSuccess());
        // إعادة تحميل العناوين بعد الحذف
        final addresses = await _addressService.getUserAddresses(event.userId);
        emit(AddressesLoaded(addresses));
        // تحميل العنوان الافتراضي بعد الحذف
        final defaultAddress = await _addressService.getDefaultAddress(event.userId);
        emit(DefaultAddressLoaded(defaultAddress));
      } catch (e) {
        emit(AddressesError('فشل في حذف العنوان'));
      }
    });

    on<SetDefaultAddress>((event, emit) async {
      try {
        await _addressService.setDefaultAddress(event.userId, event.addressId);
        emit(AddressOperationSuccess());
        // إعادة تحميل العناوين بعد تعيين العنوان الافتراضي
        final addresses = await _addressService.getUserAddresses(event.userId);
        emit(AddressesLoaded(addresses));
        // تحميل العنوان الافتراضي بعد التعيين
        final defaultAddress = await _addressService.getDefaultAddress(event.userId);
        emit(DefaultAddressLoaded(defaultAddress));
        // أعد تحميل العناوين مرة أخرى لضمان تحديث القائمة
        final addressesAfter = await _addressService.getUserAddresses(event.userId);
        emit(AddressesLoaded(addressesAfter));
      } catch (e) {
        emit(AddressesError('فشل في تعيين العنوان الافتراضي'));
      }
    });
  }
} 