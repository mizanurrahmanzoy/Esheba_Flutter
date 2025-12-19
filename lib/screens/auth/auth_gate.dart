import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/user/user_main_shell.dart';
// import 'package:esheba_fixian/screens/user/user_root_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../provider/provider_home_screen.dart';
// import '../user/user_home_screen.dart';
import '../../services/category_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String> _resolveAccountType(String uid) async {
    // 1️⃣ Check CUSTOMER
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .get();

    if (customerDoc.exists) {
      await CategoryService.getCategories();
      return 'customer';
    }

    // 2️⃣ Check PROVIDER
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (providerDoc.exists) {
      await CategoryService.getCategories();
      return 'provider';
    }

    // ❌ No account record
    throw Exception("Account data not found");
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

        // ✅ Logged in → resolve account type
        return FutureBuilder<String>(
          future: _resolveAccountType(uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnap.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    "Account data not found.\nPlease contact support.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final role = roleSnap.data!;

            if (role == 'provider') {
              return const ProviderHomeScreen();
            } else {
              return const UserMainShell();
            }
          },
        );
      },
    );
  }
}
