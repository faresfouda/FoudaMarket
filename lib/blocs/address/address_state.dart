import '../../models/address_model.dart';
import 'package:equatable/equatable.dart';

abstract class AddressState extends Equatable {
  const AddressState();
  @override
  List<Object?> get props => [];
}

class AddressesLoading extends AddressState {}

class AddressesLoaded extends AddressState {
  final List<AddressModel> addresses;
  const AddressesLoaded(this.addresses);
  @override
  List<Object?> get props => [addresses];
}

class AddressesError extends AddressState {
  final String message;
  const AddressesError(this.message);
  @override
  List<Object?> get props => [message];
}

class AddressOperationSuccess extends AddressState {}

class DefaultAddressLoading extends AddressState {}

class DefaultAddressLoaded extends AddressState {
  final AddressModel? defaultAddress;
  const DefaultAddressLoaded(this.defaultAddress);
  @override
  List<Object?> get props => [defaultAddress];
}

class DefaultAddressError extends AddressState {
  final String message;
  const DefaultAddressError(this.message);
  @override
  List<Object?> get props => [message];
} 