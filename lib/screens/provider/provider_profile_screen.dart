import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/provider_cache.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  Map<String, dynamic>? provider;
  bool loading = true;

  bool contactVisible = true;
  bool locationVisible = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // 1️⃣ Load cached data first
    final cached = await ProviderCache.load();
    if (cached != null) {
      setState(() {
        provider = cached;
        contactVisible = cached['contactVisible'] ?? true;
        locationVisible = cached['locationVisible'] ?? true;
        loading = false;
      });
    }

    // 2️⃣ Always refresh from Firestore (important)
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (!doc.exists) {
      setState(() {
        loading = false;
      });
      return;
    }

    final data = doc.data()!;
    await ProviderCache.save(data);

    setState(() {
      provider = data;
      contactVisible = data['contactVisible'] ?? true;
      locationVisible = data['locationVisible'] ?? true;
      loading = false;
    });
  }

  Future<void> _updateVisibility() async {
    if (provider == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .update({
      'contactVisible': contactVisible,
      'locationVisible': locationVisible,
    });

    provider!['contactVisible'] = contactVisible;
    provider!['locationVisible'] = locationVisible;
    await ProviderCache.save(provider!);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider == null) {
      return const Scaffold(
        body: Center(
          child: Text("Provider profile not found"),
        ),
      );
    }

    final image = provider!['image'];
    final name = provider!['name'] ?? 'Provider';
    final phone = provider!['phone'] ?? 'Not set';
    final location = provider!['location'] ?? 'Not set';
    final rating = provider!['rating'] ?? 0;
    final accuracy = provider!['accuracy'] ?? 100;
    final balance = provider!['balance'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 👤 Avatar
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  image != null && image.toString().isNotEmpty
                      ? NetworkImage(image)
                      : null,
              child: image == null || image.toString().isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),

          const SizedBox(height: 14),

          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),
          Center(child: Text("⭐ Rating: $rating")),
          Center(child: Text("🎯 Accuracy: $accuracy%")),
          Center(child: Text("💰 Balance: $balance")),

          const Divider(height: 32),

          /// ☎ Phone visibility
          SwitchListTile(
            title: const Text("Show Phone Number"),
            subtitle: Text(phone),
            value: contactVisible,
            onChanged: (v) {
              setState(() => contactVisible = v);
              _updateVisibility();
            },
          ),
          /// Availability
          SwitchListTile(
            title: const Text("Available for Jobs"),
            subtitle: const Text("Toggle your availability to accept new jobs"),
            value: provider!['isAvailable'] ?? true,
            onChanged: (v) async {
              final uid = FirebaseAuth.instance.currentUser!.uid;

              await FirebaseFirestore.instance
                  .collection('providers')
                  .doc(uid)
                  .update({
                'isAvailable': v,
              });

              setState(() {
                provider!['isAvailable'] = v;
              });
              await ProviderCache.save(provider!);
            },
          ),
          /// 📍 Location visibility
          SwitchListTile(
            title: const Text("Show Location"),
            subtitle: Text(location),
            value: locationVisible,
            onChanged: (v) {
              setState(() => locationVisible = v);
              _updateVisibility();
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Edit Profile"),
            onPressed: () {
              Navigator.pushNamed(context, '/provider-edit-profile');
            },
          ),
        ],
      ),
    );
  }
}
