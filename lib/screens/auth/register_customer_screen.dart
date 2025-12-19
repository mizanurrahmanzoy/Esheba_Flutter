import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/services/location_service.dart';
import 'package:esheba_fixian/services/manual_location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() =>
      _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  DateTime? dob;
  bool agree = false;
  bool loading = false;

  double? lat;
  double? lng;

  File? profileImage;

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
    }
  }

  /* ---------------- CLOUDINARY UPLOAD ---------------- */

  Future<String?> uploadToCloudinary(File image) async {
    const cloudName = "YOUR_CLOUD_NAME";
    const uploadPreset = "YOUR_UNSIGNED_PRESET";

    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final req = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

    final res = await req.send();
    if (res.statusCode != 200) return null;

    final body = await res.stream.bytesToString();
    return jsonDecode(body)['secure_url'];
  }

  /* ---------------- REGISTER ---------------- */

  Future<void> register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.length < 6 ||
        phoneCtrl.text.isEmpty ||
        locationCtrl.text.isEmpty ||
        dob == null ||
        lat == null ||
        lng == null) {
      _error("Please fill all required fields");
      return;
    }

    if (!agree) {
      _error("You must agree to Terms & Conditions");
      return;
    }

    setState(() => loading = true);

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      String? photoUrl;
      if (profileImage != null) {
        photoUrl = await uploadToCloudinary(profileImage!);
      }

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .set({
        'uid': uid,
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'lat': lat,
        'lng': lng,
        'photoUrl': photoUrl,
        /// Premium 
        'isPremium': false,
        
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      _error(e.toString());
    }

    setState(() => loading = false);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Create Customer Account"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 👤 PROFILE IMAGE
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  child: profileImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 24),

            /// 🧾 FORM CARD
            _card(
              Column(
                children: [
                  _input(nameCtrl, "Full Name"),
                  _input(emailCtrl, "Email"),
                  _input(passCtrl, "Password", obscure: true),
                  _input(phoneCtrl, "Phone Number",
                      type: TextInputType.phone),

                  const SizedBox(height: 12),

                  /// 📅 DOB
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Date of Birth"),
                    subtitle: Text(
                      dob == null
                          ? "Select date"
                          : "${dob!.day}/${dob!.month}/${dob!.year}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => dob = d);
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 📍 LOCATION
                  TextField(
                    controller: locationCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Location",
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.my_location),
                        onSelected: (v) async {
                          if (v == 'gps') {
                            final res = await LocationService
                                .getCurrentLocation();
                            if (res != null) {
                              setState(() {
                                locationCtrl.text = res.address;
                                lat = res.lat;
                                lng = res.lng;
                              });
                            } else {
                              _error("GPS failed");
                            }
                          } else {
                            final res =
                                await ManualLocationService.pickLocation(
                                    context);
                            if (res != null) {
                              setState(() {
                                locationCtrl.text = res.address;
                                lat = res.lat;
                                lng = res.lng;
                              });
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'gps',
                            child: Text("Use GPS"),
                          ),
                          PopupMenuItem(
                            value: 'manual',
                            child: Text("Search manually"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  CheckboxListTile(
                    value: agree,
                    onChanged: (v) => setState(() => agree = v!),
                    title: const Text("I agree to Terms & Conditions"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🚀 SUBMIT BUTTON
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label, {
    bool obscure = false,
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
