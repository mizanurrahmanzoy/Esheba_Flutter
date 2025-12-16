import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersUserScreen extends StatelessWidget {
  const MyOrdersUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .where('userId', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('You have no orders.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final status = d['status'] ?? '';
              return ListTile(
                title: Text("Order #${docs[i].id.substring(0,6)} • Tk ${d['amount']}"),
                subtitle: Text("Status: $status"),
                onTap: () {
                  // show a small detail dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Order Details'),
                      content: Text('Service: ${d['serviceId']}\nProvider: ${d['providerId']}\nStatus: $status'),
                      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
