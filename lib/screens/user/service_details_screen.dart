import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId, required Map<String, dynamic> service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Map<String, dynamic>? service;
  Map<String, dynamic>? provider;

  bool loading = true;
  bool booking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .get();

    if (!serviceDoc.exists) return;

    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(serviceDoc['providerId'])
        .get();

    setState(() {
      service = serviceDoc.data();
      provider = providerDoc.data();
      loading = false;
    });
  }

  // ---------------- 📞 CALL PROVIDER ----------------

  Future<void> _callProvider(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ---------------- 📍 OPEN MAP ----------------

  Future<void> _openMap(double lat, double lng) async {
  final googleMapsUrl =
      Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

  try {
    await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint("Map launch error: $e");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not open map")),
    );
  }
}


  // ---------------- 📦 CREATE ORDER ----------------

  Future<void> _bookService() async {
    setState(() => booking = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final orderNumber = "ORD-${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance.collection('orders').add({
        'orderNumber': orderNumber,
        'serviceId': widget.serviceId,
        'providerId': service!['providerId'],
        'customerId': user.uid,
        'price': service!['price'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order placed successfully (#$orderNumber)")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to place order")),
      );
    }

    setState(() => booking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final contactVisible = provider?['contactVisible'] == true;
    final locationVisible = provider?['locationVisible'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Service Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 SERVICE CARD
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service?['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(service?['description'] ?? ''),
                  const SizedBox(height: 12),
                  Text(
                    "৳ ${service?['price']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 PROVIDER INFO
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Provider",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: provider?['image'] != null
                            ? NetworkImage(provider!['image'])
                            : null,
                        child: provider?['image'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider?['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  /// 📞 CONTACT
                  if (contactVisible)
                    InkWell(
                      onTap: () => _callProvider(provider!['phone']),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            provider!['phone'],
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _infoRow(
                      Icons.phone,
                      "Contact hidden by provider",
                    ),

                  const SizedBox(height: 12),

                  /// 📍 LOCATION
                  if (locationVisible &&
                      provider?['lat'] != null &&
                      provider?['lng'] != null)
                    InkWell(
                      onTap: () => _openMap(
                        provider!['lat'],
                        provider!['lng'],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider?['location'] ?? '',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Icon(Icons.map),
                        ],
                      ),
                    )
                  else
                    _infoRow(
                      Icons.location_on,
                      "Location hidden by provider",
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// 🔹 BOOK BUTTON
            booking
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _bookService,
                      child: const Text(
                        "Book Service",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
