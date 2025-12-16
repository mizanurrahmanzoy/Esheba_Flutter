import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'service_detail_screen.dart';

class ServiceListUserScreen extends StatelessWidget {
  const ServiceListUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('services')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No services available.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null && data['imageUrl'] != ''
                      ? Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.build, size: 40),
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Text("Tk ${data['price']} • ${data['location'] ?? ''}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(serviceId: docs[i].id, data: {},),
                      ),
                    );
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
