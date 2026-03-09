import '../constants/app_constants.dart';

class DeliveryZone {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  const DeliveryZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  factory DeliveryZone.fallback() {
    return DeliveryZone(
      name: AppConstants.mallName,
      latitude: AppConstants.mallCenter.latitude,
      longitude: AppConstants.mallCenter.longitude,
      radiusKm: AppConstants.serviceRadiusKm,
    );
  }

  factory DeliveryZone.fromMap(Map<String, dynamic> data) {
    final fallback = DeliveryZone.fallback();
    final lat = data['latitude'];
    final lng = data['longitude'];
    final radius = data['radiusKm'];

    return DeliveryZone(
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String)
          : fallback.name,
      latitude: lat is num ? lat.toDouble() : fallback.latitude,
      longitude: lng is num ? lng.toDouble() : fallback.longitude,
      radiusKm: radius is num ? radius.toDouble() : fallback.radiusKm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
    };
  }
}
