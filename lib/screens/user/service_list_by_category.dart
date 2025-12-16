import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceListByCategoryScreen extends StatelessWidget {
  final String? category;

  const ServiceListByCategoryScreen({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    Query servicesQuery = FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true);

    if (category != null) {
      servicesQuery = servicesQuery.where('category', isEqualTo: category);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category ?? "All Services"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: servicesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No services available"),
            );
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['title'] ?? 'No title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['category'] ?? ''),
                      const SizedBox(height: 4),
                      Text("৳ ${data['price']}"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 🔜 Next: Service details + order confirmation
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
