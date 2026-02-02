import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'MallDash';
  static const String mallName = 'SM Megamall';
  static const String defaultAddress = 'Entrance A, ${mallName}';
  static const bool enableMaps = false;
  static const String adminPhone = '9408362739';

  static const LatLng mallCenter = LatLng(14.5853, 121.0568);
  static const double serviceRadiusKm = 10;
}

@immutable
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
