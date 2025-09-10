import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/blocs/category/category_bloc.dart';
import 'package:fouda_market/blocs/category/category_event.dart';
import 'package:fouda_market/blocs/category/category_state.dart';
import 'package:fouda_market/models/category_model.dart';
import 'package:fouda_market/views/category/category_screen.dart';
import 'package:fouda_market/components/category_card.dart';
import 'package:fouda_market/theme/appcolors.dart';

class CategoryListWidget extends StatelessWidget {
  const CategoryListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأقسام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              _buildLoadingIndicator(90),
            ],
          );
        } else if (state is CategoriesLoaded && state.categories.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأقسام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              _CategoryList(categories: state.categories),
            ],
          );
        } else if (state is CategoriesError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأقسام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              _buildErrorView('فشل في تحميل الفئات'),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLoadingIndicator(double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.orangeColor),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;

  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return SizedBox.shrink();
    }
    return SizedBox(
      height: 120, // زيادة الارتفاع من 110 إلى 120 لاستيعاب الحجم الجديد
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          Color bgColor = Colors.orange.shade100; // لون افتراضي أفضل

          // تحسين معالجة الألوان
          if (category.color != null && category.color!.isNotEmpty) {
            try {
              // التعامل مع الألوان بصيغة hex
              String colorString = category.color!;
              if (colorString.startsWith('#')) {
                colorString = colorString.replaceFirst('#', '0xff');
              } else if (!colorString.startsWith('0x')) {
                colorString = '0xff$colorString';
              }
              bgColor = Color(int.parse(colorString));
            } catch (e) {
              print('خطأ في تحليل لون الفئة: $e');
              bgColor = Colors.orange.shade100;
            }
          }

          return CategoryCard(
            imageUrl: category.imageUrl ?? '',
            categoryName: category.name,
            bgColor: bgColor,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(
                    categoryName: category.name,
                    categoryId: category.id,
                  ),
                ),
              );
              // إعادة تحميل الفئات بعد العودة
              context.read<CategoryBloc>().add(const FetchCategories());
            },
          );
        },
      ),
    );
  }
}
