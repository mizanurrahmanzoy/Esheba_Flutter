import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Service Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get(),
        builder: (context, serviceSnap) {
          if (!serviceSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final service = serviceSnap.data!.data() as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('providers')
                .doc(service['providerId'])
                .get(),
            builder: (context, providerSnap) {
              if (!providerSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final provider =
                  providerSnap.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SERVICE INFO
                    Text(
                      service['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(service['description']),
                    const SizedBox(height: 8),
                    Text(
                      "৳ ${service['price']}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(height: 32),

                    // PROVIDER INFO
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              NetworkImage(provider['image']),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("⭐ ${provider['rating']}"),
                            Text("Accuracy: ${provider['accuracy']}%"),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CONTACT INFO (CONTROLLED)
                    if (service['showPhone'] == true)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(provider['phone']),
                      ),

                    if (service['showLocation'] == true)
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(provider['location']),
                      ),

                    const SizedBox(height: 24),

                    // BOOK BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Confirm Booking"),
                              content: const Text(
                                  "Do you want to place this order?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // 🔥 PLACE ORDER HERE
                                  },
                                  child: const Text("Confirm"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text("Book Service"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
