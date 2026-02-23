import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const AppSearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search products in ${AppConstants.mallName}',
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
