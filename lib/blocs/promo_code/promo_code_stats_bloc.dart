import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/promo_code_service.dart';
import 'promo_code_stats_event.dart';
import 'promo_code_stats_state.dart';

class PromoCodeStatsBloc extends Bloc<PromoCodeStatsEvent, PromoCodeStatsState> {
  final PromoCodeService _promoCodeService = PromoCodeService();

  PromoCodeStatsBloc() : super(PromoCodeStatsInitial()) {
    on<LoadPromoCodeStats>(_onLoadPromoCodeStats);
  }

  Future<void> _onLoadPromoCodeStats(LoadPromoCodeStats event, Emitter<PromoCodeStatsState> emit) async {
    emit(PromoCodeStatsLoading());
    try {
      final stats = await _promoCodeService.getPromoCodeStats();
      emit(PromoCodeStatsLoaded(stats));
    } catch (e) {
      emit(PromoCodeStatsError('فشل في تحميل إحصائيات أكواد الخصم: $e'));
    }
  }
} 