import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final skillController = TextEditingController();

  File? nidFront;
  File? nidBack;

  bool isLoading = false;

  Future<void> pickFrontNID() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        nidFront = File(picked.path);
      });
    }
  }

  Future<void> pickBackNID() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        nidBack = File(picked.path);
      });
    }
  }

  Future<String> uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> registerProvider() async {
    if (nidFront == null || nidBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload both NID images")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final frontUrl =
          await uploadImage(nidFront!, "nid/$uid/front.jpg");
      final backUrl =
          await uploadImage(nidBack!, "nid/$uid/back.jpg");

      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'skill': skillController.text.trim(),
        'nidFrontUrl': frontUrl,
        'nidBackUrl': backUrl,
        'verified': false,
        'createdAt': DateTime.now(),
      });

      // update main user role
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'provider',
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: skillController,
              decoration: const InputDecoration(
                labelText: "Skill (e.g., Electrician, Plumber)",
              ),
            ),
            const SizedBox(height: 20),

            // NID front
            Row(
              children: [
                ElevatedButton(
                  onPressed: pickFrontNID,
                  child: const Text("Upload NID Front"),
                ),
                const SizedBox(width: 12),
                nidFront != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Text("Not uploaded"),
              ],
            ),

            const SizedBox(height: 10),

            // NID back
            Row(
              children: [
                ElevatedButton(
                  onPressed: pickBackNID,
                  child: const Text("Upload NID Back"),
                ),
                const SizedBox(width: 12),
                nidBack != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Text("Not uploaded"),
              ],
            ),

            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerProvider,
                    child: const Text("Submit Registration"),
                  ),
          ],
        ),
      ),
    );
  }
}
