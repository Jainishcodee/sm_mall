import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'delivery_zone_provider.dart';

enum LocationStatus {
  idle,
  loading,
  permissionDenied,
  serviceDisabled,
  serviceable,
  outOfRange,
  error,
}

class LocationState {
  final LocationStatus status;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final double? serviceRadiusKm;
  final String? zoneName;
  final String? message;

  const LocationState({
    required this.status,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
    this.zoneName,
    this.message,
  });

  bool get isServiceable => status == LocationStatus.serviceable;
  bool get isOutOfRange => status == LocationStatus.outOfRange;

  /// True when we already have a definitive GPS result (serviceable or outOfRange).
  bool get hasResult =>
      status == LocationStatus.serviceable ||
      status == LocationStatus.outOfRange;
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier(this._ref)
    : super(const LocationState(status: LocationStatus.idle));

  final Ref _ref;
  bool _checking = false;

  /// Check location. If [force] is false and we already have a GPS result,
  /// skip the re-check to avoid a flicker / race condition.
  Future<void> checkLocation({bool force = false}) async {
    // Prevent overlapping checks — this was causing the race condition.
    if (_checking) return;

    // If we already have a definitive result and this isn't a forced refresh,
    // keep the existing state.
    if (!force && state.hasResult) return;

    _checking = true;
    state = const LocationState(status: LocationStatus.loading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = const LocationState(
          status: LocationStatus.serviceDisabled,
          message: 'Location services are disabled.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = const LocationState(
          status: LocationStatus.permissionDenied,
          message: 'Location permission denied.',
        );
        return;
      }

      final zone = await _ref.read(deliveryZoneProvider.future);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      final distanceKm = distanceMeters / 1000;

      if (distanceKm > zone.radiusKm) {
        state = LocationState(
          status: LocationStatus.outOfRange,
          distanceKm: distanceKm,
          latitude: position.latitude,
          longitude: position.longitude,
          serviceRadiusKm: zone.radiusKm,
          zoneName: zone.name,
          message:
              'Service is available within ${zone.radiusKm.toStringAsFixed(0)} km of ${zone.name}.',
        );
      } else {
        state = LocationState(
          status: LocationStatus.serviceable,
          distanceKm: distanceKm,
          latitude: position.latitude,
          longitude: position.longitude,
          serviceRadiusKm: zone.radiusKm,
          zoneName: zone.name,
        );
      }
    } catch (error) {
      state = LocationState(
        status: LocationStatus.error,
        message: error.toString(),
      );
    } finally {
      _checking = false;
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(ref),
);
