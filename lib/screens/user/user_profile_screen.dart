import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('customers')
            .doc(uid)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 🔵 HEADER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          backgroundImage: data['image'] != null
                              ? NetworkImage(data['image'])
                              : null,
                          child: data['image'] == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.blue)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['email'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        if (data['location'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['location'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 📄 DETAILS CARD
                  _infoCard(
                    icon: Icons.phone,
                    title: "Phone",
                    value: data['phone'] ?? "Not provided",
                  ),
                  _infoCard(
                    icon: Icons.cake,
                    title: "Date of Birth",
                    value: data['dob'] ?? "Not provided",
                  ),
                  _infoCard(
                    icon: Icons.star,
                    title: "Account Type",
                    value: data['isPremium'] == true
                        ? "Premium Member"
                        : "Free Member",
                  ),
                  _infoCard(
                    icon: Icons.calendar_today,
                    title: "Joined On",
                    value: data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(' ')
                            .first
                        : "—",
                  ),

                  const SizedBox(height: 28),

                  /// 🚪 LOGOUT
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => _logout(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ℹ️ Info Tile
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
