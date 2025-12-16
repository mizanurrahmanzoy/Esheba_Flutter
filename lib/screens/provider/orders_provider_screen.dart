import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key});

  Future<void> _updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('providerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No orders assigned.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              final status = d['status'] ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text("Order #${id.substring(0,6)} • Tk ${d['amount']}"),
                  subtitle: Text("Status: $status"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _updateStatus(id, v),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'accepted', child: Text('Accept')),
                      const PopupMenuItem(value: 'in_progress', child: Text('Start Work')),
                      const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
