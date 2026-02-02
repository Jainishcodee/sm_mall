import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

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
  final String? message;

  const LocationState({
    required this.status,
    this.distanceKm,
    this.message,
  });

  bool get isServiceable => status == LocationStatus.serviceable;
  bool get isOutOfRange => status == LocationStatus.outOfRange;
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState(status: LocationStatus.idle));

  Future<void> checkLocation() async {
    state = const LocationState(status: LocationStatus.loading);

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

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        AppConstants.mallCenter.latitude,
        AppConstants.mallCenter.longitude,
      );
      final distanceKm = distanceMeters / 1000;
      if (distanceKm > AppConstants.serviceRadiusKm) {
        state = LocationState(
          status: LocationStatus.outOfRange,
          distanceKm: distanceKm,
          message: 'Service is available within 10 km of the mall.',
        );
      } else {
        state = LocationState(
          status: LocationStatus.serviceable,
          distanceKm: distanceKm,
        );
      }
    } catch (error) {
      state = LocationState(
        status: LocationStatus.error,
        message: error.toString(),
      );
    }
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);
