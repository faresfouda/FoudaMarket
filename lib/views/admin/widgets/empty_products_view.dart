import 'package:flutter/material.dart';

class EmptyProductsView extends StatelessWidget {
  final String searchQuery;

  const EmptyProductsView({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'لا توجد منتجات تطابق البحث'
                : 'لا توجد منتجات في هذه الفئة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة أو تحقق من الفلاتر',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
