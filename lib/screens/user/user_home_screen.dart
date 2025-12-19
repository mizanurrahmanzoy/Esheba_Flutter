import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/user/service_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Map<String, dynamic>? user;
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .get();

    setState(() {
      user = doc.data();
      loadingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                loadingUser ? _profileSkeleton() : _profileHeader(),

                const SizedBox(height: 24),

                _sectionTitle("🔥 Most Ordered Services"),
                _mostOrderedServices(),

                const SizedBox(height: 28),

                _sectionTitle("🆕 Latest Services"),
                _latestServices(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PROFILE HEADER ----------------

  Widget _profileHeader() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user?['image'] != null
                  ? NetworkImage(user!['image'])
                  : null,
              child: user?['image'] == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['location'] ?? 'Set your location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "3",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileSkeleton() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ---------------- SECTIONS ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // ---------------- MOST ORDERED ----------------

  Widget _mostOrderedServices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('orderCount', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _serviceSkeleton();
        }

        final docs = snapshot.data!.docs;

        // Fallback → recent orders if no popular
        if (docs.isEmpty ||
            ((docs.first.data() as Map)['orderCount'] ?? 0) == 0) {
          return _recentOrders();
        }

        return _serviceList(docs);
      },
    );
  }

  // ---------------- RECENT ORDERS ----------------

  Widget _recentOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("No recent orders found"),
          );
        }

        return _serviceList(snapshot.data!.docs);
      },
    );
  }

  // ---------------- LATEST SERVICES ----------------

  Widget _latestServices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _serviceSkeleton();
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text("No services available"),
          );
        }

        return _serviceList(snapshot.data!.docs);
      },
    );
  }

  // ---------------- SERVICE CARD LIST ----------------
  Widget _serviceList(List<QueryDocumentSnapshot> docs) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 12),
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final doc = docs[i];
          final data = doc.data() as Map<String, dynamic>;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailsScreen(
                    serviceId: doc.id, // 🔥 IMPORTANT
                    service: data,
                  ),
                ),
              );
            },
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF464646).withOpacity(.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.handyman, color: Colors.blue, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    data['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    "৳ ${data['price']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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

  // ---------------- SKELETON ----------------

  Widget _serviceSkeleton() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 160,
          decoration: BoxDecoration(
            // color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
