import 'package:equatable/equatable.dart';

abstract class PromoCodeStatsState extends Equatable {
  const PromoCodeStatsState();

  @override
  List<Object?> get props => [];
}

class PromoCodeStatsInitial extends PromoCodeStatsState {}
class PromoCodeStatsLoading extends PromoCodeStatsState {}
class PromoCodeStatsLoaded extends PromoCodeStatsState {
  final Map<String, dynamic> stats;
  const PromoCodeStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}
class PromoCodeStatsError extends PromoCodeStatsState {
  final String message;
  const PromoCodeStatsError(this.message);
  @override
  List<Object?> get props => [message];
} 