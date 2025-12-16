import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final bidsRef = FirebaseFirestore.instance
        .collection('bids')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),

      body: Column(
        children: [
          // ---------------- REQUEST DETAILS ----------------
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('requests')
                .doc(requestId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Budget: ${data['budget']} Tk"),
                    Text("Location: ${data['location']}"),
                    const SizedBox(height: 10),
                    Text(data['description']),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text("Bids",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),

          // ---------------- BIDS LIST ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bidsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No one has placed a bid yet.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final bid = docs[i].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          "${bid['amount']} Tk",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(bid['message']),

                        trailing: ElevatedButton(
                          onPressed: () async {
                            // CREATE ORDER
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .add({
                              'requestId': requestId,
                              'providerId': bid['providerId'],
                              'amount': bid['amount'],
                              'status': 'ongoing',
                              'createdAt': DateTime.now(),
                            });

                            // UPDATE BID STATUS
                            await FirebaseFirestore.instance
                                .collection('bids')
                                .doc(docs[i].id)
                                .update({'status': 'accepted'});

                            // UPDATE REQUEST STATUS
                            await FirebaseFirestore.instance
                                .collection('requests')
                                .doc(requestId)
                                .update({'status': 'assigned'});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Bid accepted! Order created.")),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Accept"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
