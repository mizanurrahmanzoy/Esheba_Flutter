import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/category_service.dart';
import '../login_screen.dart';
import '../provider/provider_home_screen.dart';
import '../user/user_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String> _loadUserRoleAndCache(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();

    if (data == null || !data.containsKey('role')) {
      throw Exception("User role not found");
    }

    // 🔥 preload categories for both user & provider
    await CategoryService.getCategories();

    return data['role'];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        final uid = authSnap.data!.uid;

        // ✅ Logged in → load role + cache
        return FutureBuilder<String>(
          future: _loadUserRoleAndCache(uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnap.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text("Failed to load user data"),
                ),
              );
            }

            final role = roleSnap.data!;

            if (role == 'provider') {
              return const ProviderHomeScreen();
            } else {
              return const UserHomeScreen();
            }
          },
        );
      },
    );
  }
}
