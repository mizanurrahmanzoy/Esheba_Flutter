import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';

class ProviderVerificationUploadScreen extends StatefulWidget {
  const ProviderVerificationUploadScreen({super.key});

  @override
  State<ProviderVerificationUploadScreen> createState() =>
      _ProviderVerificationUploadScreenState();
}

class _ProviderVerificationUploadScreenState
    extends State<ProviderVerificationUploadScreen> {
  File? nidFront;
  File? nidBack;

  bool submitting = false;
  bool _isPicking = false;

  // ================= IMAGE PICK FLOW =================

  Future<void> _selectImage(bool isFront) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final source = await _pickSource();
      if (source == null) return;

      File? raw;

      if (source == 'camera') {
        raw = await _openCamera();
      } else {
        raw = await _pickFile();
      }

      if (raw == null) return;

      final cropped = await _cropImage(raw);
      if (cropped == null) return;

      if (!mounted) return;
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

  Future<String?> _pickSource() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose File'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return null;
    return File(result.files.single.path!);
  }

  Future<File?> _openCamera() async {
    final cameras = await availableCameras();
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => NIDCameraScreen(camera: cameras.first),
      ),
    );
  }

  Future<File?> _cropImage(File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop NID',
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop NID'),
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
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    )
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return json.decode(body)['secure_url'];
  }

  Future<void> _submit() async {
    if (nidFront == null || nidBack == null) return;

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

      debugPrint('Front: $frontUrl');
      debugPrint('Back: $backUrl');

      // 👉 Save URLs to Firebase here
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 160,
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
                    child: Icon(Icons.add_a_photo, size: 40),
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// CAMERA SCREEN WITH WHITE NID GUIDE
// =======================================================

class NIDCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const NIDCameraScreen({super.key, required this.camera});

  @override
  State<NIDCameraScreen> createState() => _NIDCameraScreenState();
}

class _NIDCameraScreenState extends State<NIDCameraScreen> {
  late CameraController controller;
  bool taking = false;

  @override
  void initState() {
    super.initState();
    controller =
        CameraController(widget.camera, ResolutionPreset.high);
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(controller),

          // WHITE GUIDE FRAME
          Center(
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: taking
                    ? null
                    : () async {
                        taking = true;
                        final pic = await controller.takePicture();
                        if (!mounted) return;
                        Navigator.pop(context, File(pic.path));
                      },
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
