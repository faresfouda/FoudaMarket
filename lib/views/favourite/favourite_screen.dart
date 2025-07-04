import 'package:flutter/material.dart';
import 'package:fodamarket/views/favourite/widgets/product_favourite.dart';
import 'package:fodamarket/components/item_container.dart';
import 'package:fodamarket/theme/appcolors.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  // Example favorite products
  final List<Map<String, String>> favorites = [
    {
      'imageUrl': 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=400&q=80',
      'productName': 'تفاح أحمر',
      'quantityInfo': '٢ كجم',
      'price': '٦٠ ج.م',
    },
    {
      'imageUrl': 'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg',
      'productName': 'موز عضوي',
      'quantityInfo': '١ كجم',
      'price': '٤٥ ج.م',
    },
  ];
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final fav = favorites[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SizedBox(
              height: 100,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orangeColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Selection checkbox and favorite button (left, side by side)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected.contains(index),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selected.add(index);
                                    } else {
                                      selected.remove(index);
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                activeColor: AppColors.orangeColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // Toggle favorite logic here
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.favorite, color: AppColors.orangeColor, size: 22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Product info (center)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fav['productName']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fav['quantityInfo']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fav['price']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orangeColor,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                        // Product image (right)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: fav['imageUrl']!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      fav['imageUrl']!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(child: Text('IMG\n64×64', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                                    ),
                                  )
                                : Center(child: Text('IMG\n64×64', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: selected.isEmpty ? null : () {
            // Add selected favorites to cart logic
          },
          child: const Text('إضافة المحدد إلى السلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.white)),
        ),
      ),
    );
  }
}
