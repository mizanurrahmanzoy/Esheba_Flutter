import 'dart:convert';
import 'dart:io';

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

  // ================= STATE RESTORATION =================

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response =
        await _picker.retrieveLostData();

    if (response.isEmpty) return;

    if (response.files != null && response.files!.isNotEmpty) {
      final XFile file = response.files!.first;
      final cropped = await _cropImage(File(file.path));
      if (cropped == null || !mounted) return;

      setState(() {
        // Default restore to front if empty, else back
        if (nidFront == null) {
          nidFront = cropped;
        } else if (nidBack == null) {
          nidBack = cropped;
        }
      });
    }
  }

  // ================= IMAGE PICK & CROP =================

  Future<void> _selectImage(bool isFront) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
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

  Future<File?> _cropImage(File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false, // ✅ Free crop
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: 'Crop Document',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    return cropped == null ? null : File(cropped.path);
  }

  // ================= UPLOAD =================

  Future<String> _uploadToCloudinary(File file, String folder) async {
    const cloudName = 'dhrtj8kqn';
    const preset = 'esheba';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      ),
    )
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (data['secure_url'] == null) {
      throw Exception('Upload failed');
    }
    return data['secure_url'];
  }

  Future<void> _submit() async {
    if (nidFront == null || nidBack == null || submitting) return;

    setState(() => submitting = true);

    try {
      final frontUrl = await _uploadToCloudinary(
        nidFront!,
        'providers/documents/nid',
      );
      final backUrl = await _uploadToCloudinary(
        nidBack!,
        'providers/documents/nid',
      );

      debugPrint('Front URL: $frontUrl');
      debugPrint('Back URL: $backUrl');

      // 👉 Save URLs + set kycStatus = pending in Firestore
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  // ================= UI =================

  Widget _preview(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    child: Icon(Icons.upload_file, size: 40),
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
      appBar: AppBar(title: const Text('Provider Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _preview('NID Front', nidFront, () => _selectImage(true)),
            const SizedBox(height: 20),
            _preview('NID Back', nidBack, () => _selectImage(false)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
