import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchFromFirestore();
  }

  // ================= CACHE =================

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('customer_profile');

    if (cached != null) {
      setState(() {
        _userData = jsonDecode(cached);
        _loading = false;
      });
    }
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_profile', jsonEncode(data));
  }

  // ================= FIRESTORE =================

  Future<void> _fetchFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .get();

      if (snap.exists) {
        final data = snap.data()!;
        setState(() {
          _userData = data;
          _loading = false;
        });
        _cacheData(data);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _fetchFromFirestore();
  }

  // ================= LOGOUT =================

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customer_profile');
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text("Profile not found"))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _headerCard(),
                          const SizedBox(height: 24),
                          _infoCard(Icons.phone, "Phone",
                              _userData!['phone'] ?? "Not provided"),
                          _infoCard(Icons.cake, "Date of Birth",
                              _userData!['dob'] ?? "Not provided"),
                          _infoCard(
                            Icons.star,
                            "Account Type",
                            _userData!['isPremium'] == true
                                ? "Premium Member"
                                : "Free Member",
                          ),
                          _infoCard(
                            Icons.calendar_today,
                            "Joined On",
                            _userData!['createdAt'] != null
                                ? (_userData!['createdAt'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split(' ')
                                    .first
                                : "—",
                          ),
                          const SizedBox(height: 28),

                          /// EDIT PROFILE
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile",
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/edit-profile');
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// LOGOUT
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout,
                                  color: Colors.red),
                              label: const Text("Logout",
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () => _logout(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ================= COMPONENTS =================

  Widget _headerCard() {
    final photoUrl = _userData!['photoUrl'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person,
                    size: 50, color: Colors.blue)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _userData!['name'] ?? '',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _userData!['email'] ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          if (_userData!['location'] != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userData!['location'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
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
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey)),
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
