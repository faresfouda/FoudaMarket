import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/promo_code/index.dart';
import '../../theme/appcolors.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({Key? key}) : super(key: key);

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل أكواد الخصم الصالحة فقط (مفعلة وغير منتهية الصلاحية)
    context.read<PromoCodeBloc>().add(LoadValidPromoCodes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
              child: Column(
                children: [
Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'اكواد الخصم',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                  const SizedBox(height: 24),
                  Expanded(
                  child: BlocBuilder<PromoCodeBloc, PromoCodeState>(
                    builder: (context, state) {
                      if (state is PromoCodeLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is PromoCodeEmpty) {
                        return _buildEmptyState();
                      } else if (state is PromoCodesLoaded) {
                        // تصفية الأكواد الصالحة فقط
                        final validPromoCodes = state.promoCodes.where((code) => code.isValid).toList();
                        if (validPromoCodes.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildPromoCodesList(validPromoCodes);
                      } else if (state is PromoCodeError) {
                        return _buildErrorState(state.message);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.discount_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أكواد خصم متاحة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تابعنا للحصول على أحدث العروض والخصومات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodesList(List<dynamic> promoCodes) {
    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: promoCodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, i) {
                        final code = promoCodes[i];
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                        color: AppColors.orangeColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                        code.code,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.orangeColor
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        '${code.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                         Icon(Icons.discount, color: AppColors.orangeColor),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                  code.description,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                                Text(
                      'صالح حتى ${_formatDate(code.expiryDate)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                if (code.minOrderAmount != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'الحد الأدنى للطلب: ${code.minOrderAmount!.toStringAsFixed(2)} جنيه',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'المتبقي: ${code.maxUsageCount - code.currentUsageCount} استخدام',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
            ),
          ],
        ),
          ),
        );
      },
      );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 