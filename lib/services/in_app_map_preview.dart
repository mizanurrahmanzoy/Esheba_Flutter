import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppMapPreview extends StatelessWidget {
  final double providerLat;
  final double providerLng;
  final double destLat;
  final double destLng;
  final String title;

  const InAppMapPreview({
    super.key,
    required this.providerLat,
    required this.providerLng,
    required this.destLat,
    required this.destLng,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final providerPoint = LatLng(providerLat, providerLng);
    final destPoint = LatLng(destLat, destLng);

    final distanceKm =
        _calculateDistance(providerLat, providerLng, destLat, destLng);

    final etaMinutes = _calculateETA(distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Route Preview",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        /// DISTANCE + ETA
        Row(
          children: [
            _chip("📏 ${distanceKm.toStringAsFixed(1)} km"),
            const SizedBox(width: 8),
            _chip("⏱ ~$etaMinutes min"),
          ],
        ),

        const SizedBox(height: 10),

        /// MAP
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: destPoint,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.esheba_fixian',
                ),

                /// ROUTE LINE
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [providerPoint, destPoint],
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),

                /// MARKERS
                MarkerLayer(
                  markers: [
                    Marker(
                      point: providerPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    Marker(
                      point: destPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// NAVIGATION BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: const Text(
              "Start Navigation",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _openNavigation(destLat, destLng),
          ),
        ),
      ],
    );
  }

  /// DISTANCE (KM)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// ETA (MINUTES)
  int _calculateETA(double distanceKm) {
    const averageSpeedKmH = 40;
    final hours = distanceKm / averageSpeedKmH;
    return (hours * 60).round();
  }

  double _degToRad(double deg) => deg * pi / 180;

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
