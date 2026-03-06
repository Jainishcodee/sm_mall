import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class MallMapCard extends StatefulWidget {
  const MallMapCard({super.key});

  @override
  State<MallMapCard> createState() => _MallMapCardState();
}

class _MallMapCardState extends State<MallMapCard> {
  MapplsMapController? _controller;

  void _onMapCreated(MapplsMapController controller) {
    _controller = controller;
    final mallPosition = LatLng(
      AppConstants.mallCenter.latitude,
      AppConstants.mallCenter.longitude,
    );
    controller.addSymbol(SymbolOptions(geometry: mallPosition));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !AppConstants.enableMaps) {
      return _MapPlaceholder(
        title: AppConstants.mallName,
        subtitle: 'Map preview not available on this platform.',
      );
    }

    final mallPosition = LatLng(
      AppConstants.mallCenter.latitude,
      AppConstants.mallCenter.longitude,
    );

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MapplsMap(
          initialCameraPosition: CameraPosition(target: mallPosition, zoom: 14),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MapPlaceholder({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.primary.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.map, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
