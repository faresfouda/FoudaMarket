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
      try {
        final defaultAddress = await _addressService.getDefaultAddress(event.userId);
        if (defaultAddress != null) {
          emit(DefaultAddressLoaded(defaultAddress));
        }
      } catch (e) {
        print('AddressBloc LoadDefaultAddress error: $e');
        emit(DefaultAddressError('فشل في تحميل العنوان الافتراضي'));
      }
    });

    on<AddAddress>((event, emit) async {
      try {
        await _addressService.addAddress(event.address);
        emit(AddressOperationSuccess());
      } catch (e) {
        emit(AddressesError('فشل في إضافة العنوان'));
      }
    });

    on<UpdateAddress>((event, emit) async {
      try {
        await _addressService.updateAddress(event.address);
        emit(AddressOperationSuccess());
      } catch (e) {
        print('UpdateAddress error: $e');
        emit(AddressesError('فشل في تحديث العنوان'));
      }
    });

    on<DeleteAddress>((event, emit) async {
      try {
        await _addressService.deleteAddress(event.addressId);
        emit(AddressOperationSuccess());
      } catch (e) {
        emit(AddressesError('فشل في حذف العنوان'));
      }
    });

    on<SetDefaultAddress>((event, emit) async {
      try {
        await _addressService.setDefaultAddress(event.userId, event.addressId);
        emit(AddressOperationSuccess());
      } catch (e) {
        print('SetDefaultAddress error: $e');
        emit(AddressesError('فشل في تعيين العنوان الافتراضي'));
      }
    });
  }
}
