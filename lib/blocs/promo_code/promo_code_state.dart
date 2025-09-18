import 'package:equatable/equatable.dart';
import '../../models/promo_code_model.dart';

abstract class PromoCodeState extends Equatable {
  const PromoCodeState();

  @override
  List<Object?> get props => [];
}

class PromoCodeInitial extends PromoCodeState {}

class PromoCodeLoading extends PromoCodeState {}

class PromoCodeEmpty extends PromoCodeState {}

class PromoCodeError extends PromoCodeState {
  final String message;
  
  const PromoCodeError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class PromoCodesLoaded extends PromoCodeState {
  final List<PromoCodeModel> promoCodes;
  
  const PromoCodesLoaded(this.promoCodes);
  
  @override
  List<Object?> get props => [promoCodes];
}

class PromoCodeCreated extends PromoCodeState {
  final PromoCodeModel promoCode;
  
  const PromoCodeCreated(this.promoCode);
  
  @override
  List<Object?> get props => [promoCode];
}

class PromoCodeUpdated extends PromoCodeState {
  final String promoCodeId;
  
  const PromoCodeUpdated(this.promoCodeId);
  
  @override
  List<Object?> get props => [promoCodeId];
}

class PromoCodeDeleted extends PromoCodeState {
  final String promoCodeId;
  
  const PromoCodeDeleted(this.promoCodeId);
  
  @override
  List<Object?> get props => [promoCodeId];
}

class PromoCodeStatusToggled extends PromoCodeState {
  final String promoCodeId;
  final bool isActive;
  
  const PromoCodeStatusToggled(this.promoCodeId, this.isActive);
  
  @override
  List<Object?> get props => [promoCodeId, isActive];
}

class PromoCodeValidated extends PromoCodeState {
  final bool isValid;
  final String message;
  final PromoCodeModel? promoCode;
  final double? discountAmount;
  
  const PromoCodeValidated({
    required this.isValid,
    required this.message,
    this.promoCode,
    this.discountAmount,
  });
  
  @override
  List<Object?> get props => [isValid, message, promoCode, discountAmount];
}

class PromoCodeStatsLoaded extends PromoCodeState {
  final Map<String, dynamic> stats;
  
  const PromoCodeStatsLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
} 