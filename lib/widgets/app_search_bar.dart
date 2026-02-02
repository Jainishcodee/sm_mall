import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search products in ${AppConstants.mallName}',
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
