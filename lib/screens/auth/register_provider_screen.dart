import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';
import '../../services/location_service.dart';
import '../../services/manual_location_service.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  File? image;
  bool loading = false;

  double? lat;
  double? lng;

  /* ---------------- IMAGE ---------------- */

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  /* ---------------- GPS LOCATION ---------------- */

  Future<void> useGpsLocation() async {
    final result = await LocationService.getCurrentLocation();
    if (result == null) {
      _error("Unable to get GPS location");
      return;
    }

    setState(() {
      locationCtrl.text = result.address;
      lat = result.lat;
      lng = result.lng;
    });
  }

  /* ---------------- MANUAL LOCATION ---------------- */

  Future<void> useManualLocation() async {
    final result = await ManualLocationService.pickLocation(context);
    if (result == null) return;

    setState(() {
      locationCtrl.text = result.address;
      lat = result.lat;
      lng = result.lng;
    });
  }

  /* ---------------- REGISTER ---------------- */

  Future<void> register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.length < 6 ||
        phoneCtrl.text.isEmpty ||
        locationCtrl.text.isEmpty ||
        lat == null ||
        lng == null) {
      _error("Fill all required fields including location");
      return;
    }

    setState(() => loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      String? imageUrl;
      if (image != null) {
        imageUrl = await CloudinaryService.uploadImage(image!);
      }

      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'uid': uid,
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'lat': lat,
        'lng': lng,
        'image': imageUrl,

        /// Provider stats
        'rating': 0,
        'accuracy': 100,
        'jobsCompleted': 0,

        /// Visibility
        'contactVisible': true,
        'locationVisible': true,

        /// KYC (future)
        'kycStatus':
            'not_started', // not_started | pending | approved | rejected

        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      _error(e.toString());
    }

    setState(() => loading = false);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Provider Registration"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// IMAGE
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: image != null ? FileImage(image!) : null,
                child: image == null
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.blue)
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            _card(
              child: Column(
                children: [
                  _input(nameCtrl, "Business Name", Icons.store),
                  _input(emailCtrl, "Email", Icons.email),
                  _input(passCtrl, "Password", Icons.lock, obscure: true),
                  _input(phoneCtrl, "Phone", Icons.phone),

                  /// LOCATION FIELD
                  TextField(
                    controller: locationCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Location",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: useGpsLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text("Use GPS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: useManualLocation,
                          icon: const Icon(Icons.search),
                          label: const Text("Search Manually"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Create Provider Account",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
