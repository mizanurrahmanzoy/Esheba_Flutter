import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../services/provider_cache.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() =>
      _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  File? image;
  bool loading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  Future<void> submit() async {
    if (image == null) return;

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = FirebaseAuth.instance.currentUser!.email;

    final imageUrl = await CloudinaryService.uploadImage(image!);
    if (imageUrl == null) return;

    final data = {
      'uid': uid,
      'name': nameCtrl.text.trim(),
      'email': email,
      'phone': phoneCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'image': imageUrl,
      'rating': 0,
      'accuracy': 100,
      'isPremium': false,
      'contactVisible': true,
      'locationVisible': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .set(data);

    await ProviderCache.save(data);

    setState(() => loading = false);

    Navigator.pushReplacementNamed(context, '/provider-home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    image != null ? FileImage(image!) : null,
                child: image == null
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Business Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submit,
                    child: const Text("Complete Setup"),
                  )
          ],
        ),
      ),
    );
  }
}
