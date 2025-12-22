import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});

  @override
  State<UserEditProfileScreen> createState() =>
      _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  File? _image;
  String? _photoUrl;
  bool _saving = false;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Cloudinary (REPLACE THESE)
  static const String cloudName = 'dhrtj8kqn';
  static const String uploadPreset = 'esheba';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 🔹 Load existing data
  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text = data['name'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _photoUrl = data['photoUrl'];
      setState(() {});
    }
  }

  // 🔹 Pick Image
  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // 🔹 CLOUDINARY UPLOAD (CORRECT)
  Future<String?> _uploadImage(File image) async {
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      debugPrint('Cloudinary upload failed');
      return null;
    }

    final responseData =
        jsonDecode(await response.stream.bytesToString());

    return responseData['secure_url'];
  }

  // 🔹 Save Profile
  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields required")),
      );
      return;
    }

    setState(() => _saving = true);

    String? imageUrl = _photoUrl;

    if (_image != null) {
      imageUrl = await _uploadImage(_image!);
    }

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .update({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'photoUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _saving = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (_photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : null) as ImageProvider?,
                child: _image == null && _photoUrl == null
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Save Profile",
                        style:
                            TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
