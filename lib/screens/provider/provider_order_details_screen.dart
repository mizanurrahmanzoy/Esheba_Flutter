import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderOrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const ProviderOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  State<ProviderOrderDetailsScreen> createState() =>
      _ProviderOrderDetailsScreenState();
}

class _ProviderOrderDetailsScreenState
    extends State<ProviderOrderDetailsScreen> {
  final TextEditingController _cancelReasonCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ORDER SUMMARY
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info("Order No", order['orderNumber'] ?? 'N/A'),
                  _info("Service", order['serviceTitle'] ?? ''),
                  _info("Price", "৳ ${order['price'] ?? 0}"),
                  _info("Status", order['status'] ?? 'pending'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// CUSTOMER + PROVIDER + MAP
            FutureBuilder(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('customers')
                    .doc(order['customerId'])
                    .get(),
                FirebaseFirestore.instance
                    .collection('providers')
                    .doc(order['providerId'])
                    .get(),
              ]),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customer =
                    snap.data![0].data();
                final provider =
                    snap.data![1].data();

                if (customer == null) {
                  return const Text("Customer not found");
                }

                final double? customerLat =
                    customer['lat']?.toDouble();
                final double? customerLng =
                    customer['lng']?.toDouble();

                final double? providerLat =
                    provider?['lat']?.toDouble();
                final double? providerLng =
                    provider?['lng']?.toDouble();

                final hasCustomerLocation =
                    customerLat != null && customerLng != null;
                final hasProviderLocation =
                    providerLat != null && providerLng != null;

                return Column(
                  children: [
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Customer",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _info("Name", customer['name'] ?? ''),
                          _info("Phone", customer['phone'] ?? ''),
                          _info("Location", customer['location'] ?? ''),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.call,
                                    color: Colors.white),
                                label: const Text("Call",
                                    style:
                                        TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                onPressed: customer['phone'] == null
                                    ? null
                                    : () => _call(customer['phone']),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.navigation,
                                    color: Colors.white),
                                label: const Text("Navigate",
                                    style:
                                        TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue),
                                onPressed: hasCustomerLocation
                                    ? () => _openExternalNav(
                                          customerLat,
                                          customerLng,
                                        )
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// MAP PREVIEW
                    if (hasCustomerLocation)
                      _mapPreview(
                        providerLat: providerLat,
                        providerLng: providerLng,
                        destLat: customerLat,
                        destLng: customerLng,
                      )
                    else
                      const Text(
                        "📍 Customer location not available",
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            _orderActions(order['status'] ?? 'pending'),
          ],
        ),
      ),
    );
  }

  // ================= MAP =================

  Widget _mapPreview({
    double? providerLat,
    double? providerLng,
    required double destLat,
    required double destLng,
  }) {
    final hasProvider =
        providerLat != null && providerLng != null;

    final distanceKm = hasProvider
        ? _distance(providerLat, providerLng, destLat, destLng)
        : null;

    final eta =
        distanceKm != null ? _eta(distanceKm) : null;

    return FutureBuilder<List<LatLng>>(
      future: hasProvider
          ? _fetchRoute(
              providerLat, providerLng, destLat, destLng)
          : Future.value([]),
      builder: (_, snap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chip(distanceKm != null
                    ? "📏 ${distanceKm.toStringAsFixed(1)} km"
                    : "📍 Distance from your location"),
                const SizedBox(width: 8),
                if (eta != null) _chip("⏱ ~$eta min"),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(destLat, destLng),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName:
                          'com.example.esheba_fixian',
                    ),
                    if (snap.hasData && snap.data!.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: snap.data!,
                            color: Colors.blue,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (hasProvider)
                          Marker(
                            point:
                                LatLng(providerLat, providerLng),
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        Marker(
                          point: LatLng(destLat, destLng),
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
          ],
        );
      },
    );
  }

  // ================= ROUTING =================

  Future<List<LatLng>> _fetchRoute(
    double sLat,
    double sLng,
    double eLat,
    double eLng,
  ) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '$sLng,$sLat;$eLng,$eLat'
        '?overview=full&geometries=geojson';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final coords =
        data['routes'][0]['geometry']['coordinates'];

    return coords
        .map<LatLng>((c) => LatLng(c[1], c[0]))
        .toList();
  }

  // ================= HELPERS =================

  Widget _info(String l, String v) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text("$l: $v"));

  Widget _card(Widget c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: c,
      );

  Widget _chip(String t) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  // ================= ORDER FLOW =================

  Widget _orderActions(String status) {
    if (status == 'pending') {
      return Row(
        children: [
          _actionBtn("Accept", Colors.green,
              () => _updateStatus('accepted')),
          const SizedBox(width: 12),
          _actionBtn("Reject", Colors.red, _cancelDialog),
        ],
      );
    }

    if (status == 'accepted') {
      return Row(
        children: [
          _actionBtn("In Progress", Colors.orange,
              () => _updateStatus('in_progress')),
          const SizedBox(width: 12),
          _actionBtn("Cancel", Colors.red, _cancelDialog),
        ],
      );
    }

    if (status == 'in_progress') {
      return _actionBtn("Mark Completed", Colors.blue,
          () => _updateStatus('completed'));
    }

    return const SizedBox();
  }

  Widget _actionBtn(
      String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // ================= ACTIONS =================

  Future<void> _updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({'status': status});
    Navigator.pop(context);
  }

  void _cancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order"),
        content: TextField(
          controller: _cancelReasonCtrl,
          decoration:
              const InputDecoration(hintText: "Reason"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId)
                  .update({
                'status': 'cancelled',
                'cancelReason': _cancelReasonCtrl.text,
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Confirm",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri.parse("tel:$phone"));
  }

  Future<void> _openExternalNav(double lat, double lng) async {
    final uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    await launchUrl(uri,
        mode: LaunchMode.externalApplication);
  }

  // ================= CALC =================

  double _distance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) *
            cos(_deg(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  int _eta(double km) => ((km / 40) * 60).round();
  double _deg(double d) => d * pi / 180;
}
