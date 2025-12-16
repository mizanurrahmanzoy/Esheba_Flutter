import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BidListScreen extends StatelessWidget {
  final String requestId;

  const BidListScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final bidsRef = FirebaseFirestore.instance
        .collection('bids')
        .where('requestId', isEqualTo: requestId)
        .orderBy('amount');

    return Scaffold(
      appBar: AppBar(title: const Text("Bids")),
      body: StreamBuilder<QuerySnapshot>(
        stream: bidsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No bids yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Bid: ${d['amount']} Tk"),
                subtitle: Text(d['message']),
                trailing: ElevatedButton(
                  onPressed: () async {
                    // Accept bid
                    await FirebaseFirestore.instance.collection("orders").add({
                      "requestId": requestId,
                      "providerId": d["providerId"],
                      "userId": FirebaseFirestore.instance.app.options.projectId,
                      "amount": d["amount"],
                      "status": "ongoing",
                      "createdAt": DateTime.now(),
                    });

                    // Update status
                    await FirebaseFirestore.instance
                        .collection('bids')
                        .doc(docs[index].id)
                        .update({"status": "accepted"});

                    Navigator.pop(context);
                  },
                  child: const Text("Accept"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
