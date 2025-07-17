import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class Locationselectionfield extends StatefulWidget {
  const Locationselectionfield({super.key});

  @override
  State<Locationselectionfield> createState() => _LocationselectionfieldState();
}

class _LocationselectionfieldState extends State<Locationselectionfield> {
  Map<dynamic, dynamic> countries = {
    'الجيزة': ['أوسيم', 'البدرشين', 'العياط'],
    'المنيا': ['ملوي', 'دير مواس', 'ابو قرقاص'],
    'البحيرة': ['دمنهور', 'كفر الدوار', 'إدكو'],
  };
  bool selected = false;
  List country = [];
  List? city = [];
  @override
  Widget build(BuildContext context) {
    List country = countries.keys.toList();
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'بلدك',
                style: TextStyle(
                  color: AppColors.mediumGrayColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        DropdownMenu(
          onSelected: (value) {
            setState(() {
              selected = true;
            });
            city = countries[value];
          },
          dropdownMenuEntries: country
              .map(
                (country) => DropdownMenuEntry(value: country, label: country),
              )
              .toList(),
        ),
        SizedBox(height: 10),
        DropdownMenu(
          enabled: selected,
          dropdownMenuEntries: city!
              .map((city) => DropdownMenuEntry(value: city, label: city))
              .toList(),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
