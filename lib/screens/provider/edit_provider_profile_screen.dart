import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';


class EditProviderProfileScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  const EditProviderProfileScreen({super.key, required this.provider});

  @override
  State<EditProviderProfileScreen> createState() =>
      _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState
    extends State<EditProviderProfileScreen> {
  final picker = ImagePicker();
  File? image;

  late TextEditingController name;
  late TextEditingController phone;
  late TextEditingController location;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.provider['name']);
    phone = TextEditingController(text: widget.provider['phone']);
    location = TextEditingController(text: widget.provider['location']);
  }

  Future<void> _pickImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: x.path,
      uiSettings: [
        AndroidUiSettings(lockAspectRatio: true),
        IOSUiSettings(),
      ],
    );

    if (cropped != null) {
      setState(() => image = File(cropped.path));
    }
  }

  Future<String?> _upload(File file) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://api.cloudinary.com/v1_1/dhrtj8kqn/image/upload'),
    )
      ..fields['upload_preset'] = 'esheba'
      ..fields['folder'] = 'providers/profile'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await req.send();
    final body = json.decode(await res.stream.bytesToString());
    return body['secure_url'];
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String? imageUrl = widget.provider['image'];
    if (image != null) {
      imageUrl = await _upload(image!);
    }

    await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .update({
      'name': name.text,
      'phone': phone.text,
      'location': location.text,
      'image': imageUrl,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    image != null ? FileImage(image!) : null,
                child: image == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: location, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
