import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'request_detail_screen.dart';

class RequestListScreen extends StatelessWidget {
  final bool isUser;

  const RequestListScreen({super.key, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // USER sees only their own requests
    // PROVIDER sees all requests
    final requestsRef = isUser
        ? FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
            .collection('requests')
            .orderBy('createdAt', descending: true)
            .limit(50);

    return Scaffold(
      appBar:
          AppBar(title: Text(isUser ? "My Requests" : "Customer Requests")),

      body: StreamBuilder<QuerySnapshot>(
        stream: requestsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(isUser
                  ? "You have no requests."
                  : "No customer requests found."),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title']),
                subtitle: Text("Budget: ${data['budget']} Tk"),

                onTap: () {
                  if (isUser) {
                    // User goes to details screen with bids
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestDetailScreen(requestId: docs[i].id),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/bid',
                      arguments: {'requestId': docs[i].id},
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
