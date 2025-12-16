import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  final Map<String, dynamic> data;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.data,
  });

  Future<void> placeOrder(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Confirm Popup
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Order"),
        content: const Text("Are you sure you want to order this service?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Save Order in Firestore
    await FirebaseFirestore.instance.collection("orders").add({
      "serviceId": serviceId,
      "serviceTitle": data["title"],
      "providerId": data["providerId"],
      "userId": uid,
      "price": data["price"],
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data["title"])),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(data["title"], style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),

            Text("Category: ${data["category"]}"),
            Text("Location: ${data["location"]}"),
            Text("Price: Tk ${data["price"]}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            const Text("Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(data["description"]),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => placeOrder(context),
              child: const Text("Order Now"),
            )
          ],
        ),
      ),
    );
  }
}
