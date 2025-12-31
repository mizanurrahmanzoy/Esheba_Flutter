import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProviderVerificationUploadScreen extends StatefulWidget {
  const ProviderVerificationUploadScreen({super.key});

  @override
  State<ProviderVerificationUploadScreen> createState() =>
      _ProviderVerificationUploadScreenState();
}

class _ProviderVerificationUploadScreenState
    extends State<ProviderVerificationUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File? nidFront;
  File? nidBack;

  bool submitting = false;
  bool _isPicking = false;

  // ================= RESTORE LOST IMAGE =================
  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null) return;

    final file = File(response.files!.first.path);
    final cropped = await _cropImage(file);
    if (cropped == null || !mounted) return;

    setState(() {
      if (nidFront == null) {
        nidFront = cropped;
      } else nidBack ??= cropped;
    });
  }

  // ================= PICK IMAGE =================
  Future<void> _selectImage(bool isFront) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from Gallery'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      final cropped = await _cropImage(File(picked.path));
      if (cropped == null || !mounted) return;

      setState(() {
        if (isFront) {
          nidFront = cropped;
        } else {
          nidBack = cropped;
        }
      });
    } finally {
      _isPicking = false;
    }
  }

  // ================= CROP =================
  Future<File?> _cropImage(File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Document',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    return cropped == null ? null : File(cropped.path);
  }

  // ================= CLOUDINARY =================
  Future<String> _uploadToCloudinary(File file) async {
    const cloudName = 'dhrtj8kqn';
    const preset = 'esheba';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    )
      ..fields['upload_preset'] = preset
      ..fields['folder'] = 'providers/documents/nid'
      ..files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (data['secure_url'] == null) {
      throw Exception('Upload failed');
    }
    return data['secure_url'];
  }

  // ================= FIRESTORE =================
  Future<void> _saveToFirestore(
      String frontUrl, String backUrl) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .set({
      'kycStatus': 'pending',
      'kycSubmittedAt': FieldValue.serverTimestamp(),
      'verification': {
        'nidFront': frontUrl,
        'nidBack': backUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'adminNote': null,
      },
    }, SetOptions(merge: true));
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (nidFront == null || nidBack == null || submitting) return;

    setState(() => submitting = true);

    try {
      final frontUrl = await _uploadToCloudinary(nidFront!);
      final backUrl = await _uploadToCloudinary(nidBack!);

      await _saveToFirestore(frontUrl, backUrl);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submitted'),
          content: const Text(
              'Your documents have been sent for admin review.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  // ================= UI =================
  Widget _preview(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              image: file != null
                  ? DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: file == null
                ? const Center(
                    child:
                        Icon(Icons.upload_file, size: 40),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Provider Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _preview('NID Front', nidFront,
                () => _selectImage(true)),
            const SizedBox(height: 20),
            _preview('NID Back', nidBack,
                () => _selectImage(false)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
