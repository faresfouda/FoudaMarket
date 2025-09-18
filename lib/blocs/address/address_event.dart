import '../../models/address_model.dart';
import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressEvent {
  final String userId;
  const LoadAddresses(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadDefaultAddress extends AddressEvent {
  final String userId;
  const LoadDefaultAddress(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddAddress extends AddressEvent {
  final AddressModel address;
  const AddAddress(this.address);
  @override
  List<Object?> get props => [address];
}

class UpdateAddress extends AddressEvent {
  final AddressModel address;
  const UpdateAddress(this.address);
  @override
  List<Object?> get props => [address];
}

class DeleteAddress extends AddressEvent {
  final String addressId;
  final String userId;
  const DeleteAddress(this.addressId, this.userId);
  @override
  List<Object?> get props => [addressId, userId];
}

class SetDefaultAddress extends AddressEvent {
  final String userId;
  final String addressId;
  const SetDefaultAddress(this.userId, this.addressId);
  @override
  List<Object?> get props => [userId, addressId];
} 