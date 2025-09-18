import 'package:equatable/equatable.dart';

abstract class PromoCodeStatsEvent extends Equatable {
  const PromoCodeStatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPromoCodeStats extends PromoCodeStatsEvent {
  const LoadPromoCodeStats();
} 