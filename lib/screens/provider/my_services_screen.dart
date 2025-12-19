import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/provider/edit_service_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Services"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('providerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't posted any services yet."),
            );
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final doc = services[i];
              final data = doc.data() as Map<String, dynamic>;

              return _serviceCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final bool isActive = data['isActive'] == true;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + STATUS
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(.15)
                        : Colors.red.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? "Active" : "Inactive",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// CATEGORY + PRICE
            Text(
              "${data['category']} • ৳${data['price']}",
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 12),

            /// ACTION BUTTONS
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditServiceScreen(
                          serviceId: docId,
                          data: data,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, docId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Service"),
        content: const Text("Are you sure you want to delete this service?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('services')
                  .doc(docId)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
