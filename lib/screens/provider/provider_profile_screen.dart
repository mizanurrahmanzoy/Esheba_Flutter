import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/provider/edit_provider_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/provider_cache.dart';
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (!snap.exists) {
      setState(() => loading = false);
      return;
    }

    provider = snap.data();
    contactVisible = provider!['contactVisible'] ?? true;
    locationVisible = provider!['locationVisible'] ?? true;

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final image = provider!['image'];
    final kycStatus = provider!['kycStatus'] ?? 'not_started';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileHeader(image),
            const SizedBox(height: 12),
            _statsRow(),
            const SizedBox(height: 16),
            Center(child: _kycBadge(kycStatus)),
            const SizedBox(height: 20),

            if (kycStatus != 'approved')
              _verifyButton(),

            _sectionTitle("Visibility"),
            _visibilityToggles(),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProviderProfileScreen(
                      provider: provider!,
                    ),
                  ),
                );
                _loadProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(String? image) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.indigo.shade100,
          backgroundImage:
              image != null ? NetworkImage(image) : null,
          child: image == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          provider!['name'],
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(provider!['email'], style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat("⭐ Rating", provider!['rating']),
        _stat("🎯 Accuracy", "${provider!['accuracy']}%"),
        _stat("💰 Balance", "৳${provider!['balance']}"),
      ],
    );
  }

  Widget _stat(String label, dynamic value) {
    return Column(
      children: [
        Text(value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _verifyButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.verified_user),
      label: const Text("Verify Profile"),
      onPressed: () {
        Navigator.pushNamed(context, '/provider-verification');
      },
    );
  }

  Widget _visibilityToggles() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Show Phone"),
            value: contactVisible,
            onChanged: (v) async {
              contactVisible = v;
              await _updateVisibility();
            },
          ),
          SwitchListTile(
            title: const Text("Show Location"),
            value: locationVisible,
            onChanged: (v) async {
              locationVisible = v;
              await _updateVisibility();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateVisibility() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .update({
      'contactVisible': contactVisible,
      'locationVisible': locationVisible,
    });
    setState(() {});
  }

  Widget _sectionTitle(String t) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _kycBadge(String status) {
    final map = {
      'approved': Colors.green,
      'pending': Colors.orange,
      'rejected': Colors.red,
    };
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: (map[status] ?? Colors.grey).withOpacity(.2),
    );
  }
}
