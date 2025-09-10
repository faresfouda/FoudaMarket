import 'package:flutter/material.dart';
import 'package:fouda_market/views/home/search_screen.dart';
import 'package:fouda_market/views/home/widgets/my_searchbutton.dart';
import 'package:fouda_market/theme/appcolors.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SearchButton()),
        const SizedBox(width: 10),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.orangeColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(openFilterOnStart: true),
                ),
              );
              // يمكنك إضافة منطق إعادة تحميل المنتجات هنا إذا أردت
            },
          ),
        ),
      ],
    );
  }
}
