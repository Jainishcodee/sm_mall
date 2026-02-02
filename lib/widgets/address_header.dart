import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';

class AddressHeader extends ConsumerWidget {
  const AddressHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final subtitle = _subtitleForState(locationState);

    return Row(
      children: [
        const Icon(Icons.location_on, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivering to',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.slate900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: AppColors.slate700),
      ],
    );
  }

  String _subtitleForState(LocationState state) {
    if (state.status == LocationStatus.serviceable ||
        state.status == LocationStatus.outOfRange) {
      return AppConstants.defaultAddress;
    }
    if (state.status == LocationStatus.permissionDenied) {
      return 'Enable location for faster delivery';
    }
    if (state.status == LocationStatus.serviceDisabled) {
      return 'Turn on location services';
    }
    return AppConstants.defaultAddress;
  }
}
