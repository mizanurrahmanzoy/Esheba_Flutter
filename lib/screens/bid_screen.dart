import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BidScreen extends StatefulWidget {
  final String requestId;
  const BidScreen({super.key, required this.requestId});

  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  final amountController = TextEditingController();
  final messageController = TextEditingController();
  bool loading = false;

  Future<void> submitBid() async {
    final providerId = FirebaseAuth.instance.currentUser!.uid;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection('bids').add({
      'requestId': widget.requestId,
      'providerId': providerId,
      'amount': int.parse(amountController.text.trim()),
      'message': messageController.text.trim(),
      'status': 'pending',
      'createdAt': DateTime.now(),
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place a Bid")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Bid Amount"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitBid,
                    child: const Text("Submit Bid"),
                  ),
          ],
        ),
      ),
    );
  }
}
