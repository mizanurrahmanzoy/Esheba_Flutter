import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;

  LocationResult({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class LocationService {
  static Future<LocationResult?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

    if (placemarks.isEmpty) return null;

    final p = placemarks.first;

    final parts = [
      // p.name,
      // p.subThoroughfare,
      p.thoroughfare,
      p.subLocality,
      p.locality,
      p.postalCode,
      p.administrativeArea,
      // p.country,
    ]
        .where((e) => e != null && e!.isNotEmpty)
        .map((e) => e!)
        .toList();

    final fullAddress = parts.join(', ');

    return LocationResult(
      address: fullAddress,
      lat: pos.latitude,
      lng: pos.longitude,
    );
  }
}
