import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/promo_code_service.dart';
import 'promo_code_event.dart';
import 'promo_code_state.dart';

class PromoCodeBloc extends Bloc<PromoCodeEvent, PromoCodeState> {
  final PromoCodeService _promoCodeService = PromoCodeService();

  PromoCodeBloc() : super(PromoCodeInitial()) {
    on<LoadPromoCodes>(_onLoadPromoCodes);
    on<LoadValidPromoCodes>(_onLoadValidPromoCodes);
    on<CreatePromoCode>(_onCreatePromoCode);
    on<UpdatePromoCode>(_onUpdatePromoCode);
    on<DeletePromoCode>(_onDeletePromoCode);
    on<TogglePromoCodeStatus>(_onTogglePromoCodeStatus);
    on<ValidatePromoCode>(_onValidatePromoCode);
    on<LoadPromoCodeStats>(_onLoadPromoCodeStats);
    on<RefreshPromoCodes>(_onRefreshPromoCodes);
  }

  Future<void> _onLoadPromoCodes(LoadPromoCodes event, Emitter<PromoCodeState> emit) async {
    print('[DEBUG] Loading promo codes...');
    emit(PromoCodeLoading());
    try {
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      print('[DEBUG] Promo codes loaded: ${promoCodes.length}');
      if (promoCodes.isEmpty) {
        emit(PromoCodeEmpty());
      } else {
        emit(PromoCodesLoaded(promoCodes));
      }
    } catch (e) {
      print('[DEBUG] Error loading promo codes: $e');
      emit(PromoCodeError('فشل في تحميل أكواد الخصم'));
    }
  }

  Future<void> _onLoadValidPromoCodes(LoadValidPromoCodes event, Emitter<PromoCodeState> emit) async {
    emit(PromoCodeLoading());
    try {
      final promoCodes = await _promoCodeService.getValidPromoCodes();
      if (promoCodes.isEmpty) {
        emit(PromoCodeEmpty());
      } else {
        emit(PromoCodesLoaded(promoCodes));
      }
    } catch (e) {
      emit(PromoCodeError(e.toString()));
    }
  }

  Future<void> _onCreatePromoCode(CreatePromoCode event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      await _promoCodeService.createPromoCode(event.promoCode);
      emit(PromoCodeCreated(event.promoCode));
      
      // إعادة تحميل قائمة أكواد الخصم
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      emit(PromoCodesLoaded(promoCodes));
    } catch (e) {
      emit(PromoCodeError('فشل في إنشاء كود الخصم: $e'));
    }
  }

  Future<void> _onUpdatePromoCode(UpdatePromoCode event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      await _promoCodeService.updatePromoCode(event.promoCodeId, event.data);
      emit(PromoCodeUpdated(event.promoCodeId));
      
      // إعادة تحميل قائمة أكواد الخصم
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      emit(PromoCodesLoaded(promoCodes));
    } catch (e) {
      emit(PromoCodeError('فشل في تحديث كود الخصم: $e'));
    }
  }

  Future<void> _onDeletePromoCode(DeletePromoCode event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      await _promoCodeService.deletePromoCode(event.promoCodeId);
      emit(PromoCodeDeleted(event.promoCodeId));
      
      // إعادة تحميل قائمة أكواد الخصم
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      if (promoCodes.isEmpty) {
        emit(PromoCodeEmpty());
      } else {
        emit(PromoCodesLoaded(promoCodes));
      }
    } catch (e) {
      emit(PromoCodeError('فشل في حذف كود الخصم: $e'));
    }
  }

  Future<void> _onTogglePromoCodeStatus(TogglePromoCodeStatus event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      await _promoCodeService.togglePromoCodeStatus(event.promoCodeId, event.isActive);
      emit(PromoCodeStatusToggled(event.promoCodeId, event.isActive));
      
      // إعادة تحميل قائمة أكواد الخصم
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      emit(PromoCodesLoaded(promoCodes));
    } catch (e) {
      emit(PromoCodeError('فشل في تغيير حالة كود الخصم: $e'));
    }
  }

  Future<void> _onValidatePromoCode(ValidatePromoCode event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      final result = await _promoCodeService.validatePromoCode(event.code, event.orderAmount);
      
      emit(PromoCodeValidated(
        isValid: result['isValid'],
        message: result['message'],
        promoCode: result['promoCode'],
        discountAmount: result['discountAmount'],
      ));
    } catch (e) {
      emit(PromoCodeError('فشل في التحقق من كود الخصم: $e'));
    }
  }

  Future<void> _onLoadPromoCodeStats(LoadPromoCodeStats event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      final stats = await _promoCodeService.getPromoCodeStats();
      emit(PromoCodeStatsLoaded(stats));
    } catch (e) {
      emit(PromoCodeError('فشل في تحميل إحصائيات أكواد الخصم: $e'));
    }
  }

  Future<void> _onRefreshPromoCodes(RefreshPromoCodes event, Emitter<PromoCodeState> emit) async {
    try {
      emit(PromoCodeLoading());
      final promoCodes = await _promoCodeService.getAllPromoCodes();
      
      if (promoCodes.isEmpty) {
        emit(PromoCodeEmpty());
      } else {
        emit(PromoCodesLoaded(promoCodes));
      }
    } catch (e) {
      emit(PromoCodeError('فشل في تحديث أكواد الخصم: $e'));
    }
  }
} 