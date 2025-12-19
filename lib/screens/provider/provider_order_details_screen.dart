import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const ProviderOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info("Order", order['orderNumber'] ?? 'ORD-XXXX'),
                  _info("Service", order['serviceTitle'] ?? 'Service'),
                  _info("Price", "৳ ${order['price'] ?? 0}"),
                  _info("Status", order['status'] ?? 'pending'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// CUSTOMER INFO
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('customers')
                  .doc(order['customerId'])
                  .get(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customer = snap.data!.data() as Map<String, dynamic>?;

                if (customer == null) {
                  return const Text("Customer not found");
                }

                return _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _info("Name", customer['name'] ?? ''),
                      _info("Phone", customer['phone'] ?? ''),
                      _info("Location", customer['location'] ?? ''),
                      const SizedBox(height: 10),

                      /// ACTION BUTTONS
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: customer['phone'] == null
                                ? null
                                : () => _call(customer['phone']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: customer['lat'] == null
                                ? null
                                : () => _openDirections(customer['lat'], customer['lng']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            /// ACCEPT / REJECT
            if ((order['status'] ?? 'pending') == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _updateStatus(context, 'accepted'),
                      child: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _updateStatus(context, 'rejected'),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text("$label: $value"),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
    });

    Navigator.pop(context);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    await launchUrl(uri);
  }

  Future<void> _openDirections(double lat, double lng) async {
    final googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";

    final uri = Uri.parse(googleMapsUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }
}
