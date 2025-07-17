import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/promo_code/index.dart';
import '../../blocs/auth/index.dart';
import '../../models/promo_code_model.dart';
import '../../theme/appcolors.dart';
import 'add_edit_promo_code_screen.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoCodeBloc>().add(LoadPromoCodes());
      context.read<PromoCodeStatsBloc>().add(LoadPromoCodeStats());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            authState.userProfile == null || 
            authState.userProfile!.role != 'admin') {
          return _buildUnauthorizedScreen();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'إدارة أكواد الخصم',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: AppColors.orangeColor),
                onPressed: () => _navigateToAddPromoCode(),
              ),
            ],
          ),
          body: BlocListener<PromoCodeBloc, PromoCodeState>(
            listener: (context, state) {
              if (state is PromoCodeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PromoCodeCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء كود الخصم بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PromoCodeUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث كود الخصم بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PromoCodeDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف كود الخصم بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Column(
              children: [
                BlocBuilder<PromoCodeStatsBloc, PromoCodeStatsState>(
                  builder: (context, statsState) {
                    if (statsState is PromoCodeStatsLoaded) {
                      return _buildStatsCard(statsState.stats);
                    } else if (statsState is PromoCodeStatsLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      );
                    } else if (statsState is PromoCodeStatsError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(statsState.message, style: TextStyle(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Expanded(
                  child: BlocBuilder<PromoCodeBloc, PromoCodeState>(
                    builder: (context, state) {
                      if (state is PromoCodeLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is PromoCodeEmpty) {
                        return _buildEmptyState();
                      } else if (state is PromoCodesLoaded) {
                        return _buildPromoCodesList(state.promoCodes);
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
        );
      },
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orangeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('إجمالي الأكواد', stats['totalCodes'].toString()),
          ),
          Expanded(
            child: _buildStatItem('مفعلة', stats['activeCodes'].toString()),
          ),
          Expanded(
            child: _buildStatItem('منتهية', stats['expiredCodes'].toString()),
          ),
          Expanded(
            child: _buildStatItem('الاستخدامات', stats['totalUsage'].toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.orangeColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
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
            'لا توجد أكواد خصم',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة كود خصم جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PromoCodeBloc>().add(LoadPromoCodes());
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodesList(List<PromoCodeModel> promoCodes) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PromoCodeBloc>().add(RefreshPromoCodes());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promoCodes.length,
        itemBuilder: (context, index) {
          final promoCode = promoCodes[index];
          return _buildPromoCodeCard(promoCode, key: ValueKey(promoCode.id)); // مرر key هنا
        },
      ),
    );
  }

  Widget _buildPromoCodeCard(PromoCodeModel promoCode, {Key? key}) {
    return Card(
      key: key, // استخدم key هنا
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: promoCode.isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: promoCode.isValid ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        promoCode.code,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: promoCode.isValid ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        promoCode.fixedAmount != null && promoCode.fixedAmount! > 0
                          ? '(${promoCode.fixedAmount!.toStringAsFixed(2)} جنيه خصم ثابت)'
                          : '(${promoCode.discountPercentage.toStringAsFixed(2)}% خصم)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${promoCode.discountPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orangeColor,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: promoCode.isActive,
                  onChanged: (value) {
                    _togglePromoCodeStatus(promoCode.id, value);
                  },
                  activeColor: AppColors.orangeColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              promoCode.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'ينتهي في: ${_formatDate(promoCode.expiryDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${promoCode.currentUsageCount}/${promoCode.maxUsageCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (promoCode.minOrderAmount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'الحد الأدنى: ${promoCode.minOrderAmount!.toStringAsFixed(2)} جنيه',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEditPromoCode(promoCode),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orangeColor,
                      side: BorderSide(color: AppColors.orangeColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletePromoCode(promoCode),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('حذف'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إدارة أكواد الخصم',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: AppColors.orangeColor.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'غير مصرح لك بالوصول',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'يجب تسجيل الدخول بحساب مدير للوصول إلى إدارة أكواد الخصم',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                'العودة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddPromoCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPromoCodeScreen(),
      ),
    );
    if (result == true) {
      context.read<PromoCodeBloc>().add(LoadPromoCodes());
      context.read<PromoCodeStatsBloc>().add(LoadPromoCodeStats());
    }
  }

  void _navigateToEditPromoCode(PromoCodeModel promoCode) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPromoCodeScreen(promoCode: promoCode),
      ),
    );
    if (result == true) {
      context.read<PromoCodeBloc>().add(LoadPromoCodes());
      context.read<PromoCodeStatsBloc>().add(LoadPromoCodeStats());
    }
  }

  void _togglePromoCodeStatus(String promoCodeId, bool isActive) {
    context.read<PromoCodeBloc>().add(TogglePromoCodeStatus(promoCodeId, isActive));
    context.read<PromoCodeStatsBloc>().add(LoadPromoCodeStats());
  }

  void _deletePromoCode(PromoCodeModel promoCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف كود الخصم "${promoCode.code}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                context.read<PromoCodeBloc>().add(DeletePromoCode(promoCode.id));
                context.read<PromoCodeStatsBloc>().add(LoadPromoCodeStats());
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل في حذف كود الخصم: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
} 