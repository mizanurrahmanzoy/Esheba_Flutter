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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Order"),
        content: const Text("Are you sure you want to order this service?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection("orders").add({
      "serviceId": serviceId,
      "serviceTitle": data["title"] ?? "",
      "providerId": data["providerId"],
      "userId": uid,
      "price": data["price"] ?? 0,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data["title"] ?? "Service";
    final category = data["category"] ?? "N/A";
    final location = data["location"] ?? "Not specified";
    final description = data["description"] ?? "No description provided";
    final price = data["price"] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(title)),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Category: $category"),
            Text("Location: $location"),

            const SizedBox(height: 8),

            Text(
              "Price: Tk $price",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(description),

            const SizedBox(height: 40),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => placeOrder(context),
                child: const Text("Order Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
