import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';





class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingItem(Icons.email, "Email"),
          _settingItem(Icons.person, "Username"),
          _settingItem(Icons.monitor_heart, "Step data source"),
          _settingItem(Icons.language, "Language"),
          _settingItem(Icons.lock, "Privacy"),

          const SizedBox(height: 16),

          /// PREMIUM CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Premium Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Inactive",
                  style: TextStyle(color: Colors.orange),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// REFERRAL CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.card_giftcard, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Refer a friend\n50% referral reward",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _settingItem(Icons.apps, "App Icon"),
          _settingItem(Icons.widgets, "Widget"),
        ],
      ),
    );
  }

  Widget _settingItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
