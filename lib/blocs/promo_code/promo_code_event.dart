import 'package:equatable/equatable.dart';
import '../../models/promo_code_model.dart';

abstract class PromoCodeEvent extends Equatable {
  const PromoCodeEvent();

  @override
  List<Object?> get props => [];
}

class LoadPromoCodes extends PromoCodeEvent {
  const LoadPromoCodes();
}

class LoadValidPromoCodes extends PromoCodeEvent {
  const LoadValidPromoCodes();
}

class CreatePromoCode extends PromoCodeEvent {
  final PromoCodeModel promoCode;
  
  const CreatePromoCode(this.promoCode);
  
  @override
  List<Object?> get props => [promoCode];
}

class UpdatePromoCode extends PromoCodeEvent {
  final String promoCodeId;
  final Map<String, dynamic> data;
  
  const UpdatePromoCode(this.promoCodeId, this.data);
  
  @override
  List<Object?> get props => [promoCodeId, data];
}

class DeletePromoCode extends PromoCodeEvent {
  final String promoCodeId;
  
  const DeletePromoCode(this.promoCodeId);
  
  @override
  List<Object?> get props => [promoCodeId];
}

class TogglePromoCodeStatus extends PromoCodeEvent {
  final String promoCodeId;
  final bool isActive;
  
  const TogglePromoCodeStatus(this.promoCodeId, this.isActive);
  
  @override
  List<Object?> get props => [promoCodeId, isActive];
}

class ValidatePromoCode extends PromoCodeEvent {
  final String code;
  final double orderAmount;
  
  const ValidatePromoCode(this.code, this.orderAmount);
  
  @override
  List<Object?> get props => [code, orderAmount];
}

class LoadPromoCodeStats extends PromoCodeEvent {
  const LoadPromoCodeStats();
}

class RefreshPromoCodes extends PromoCodeEvent {
  const RefreshPromoCodes();
} 