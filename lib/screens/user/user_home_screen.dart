import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/user/category_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/category_service.dart';
// import '../../models/category_model.dart';
import 'all_categories_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Map<String, dynamic>? user;
  List<CategoryModel> categories = [];

  bool loadingUser = true;
  bool loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .get();

    final cats = await CategoryService.getCategories();

    setState(() {
      user = userDoc.data();
      categories = cats.cast<CategoryModel>();
      loadingUser = false;
      loadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🟦 PROFILE HEADER
                loadingUser ? _profileSkeleton() : _profileHeader(),

                const SizedBox(height: 24),

                /// 🧩 CATEGORIES
                const Text(
                  "Popular Services",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                loadingCategories
                    ? _categorySkeleton()
                    : _categoryList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- PROFILE ----------------

  Widget _profileHeader() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user!['image'] != null
                  ? NetworkImage(user!['image'])
                  : null,
              child: user!['image'] == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user!['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!['location'] ?? "Set your location",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "3",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileSkeleton() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// ---------------- CATEGORIES ----------------

  Widget _categoryList(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text("No categories available"));
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length > 4 ? 5 : categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          if (index == 4) return _viewAllCard(context);

          final cat = categories[index];
          return CategoryCard(cat: cat);
        },
      ),
    );
  }

  Widget _categorySkeleton() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _viewAllCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllCategoriesScreen(categories: categories),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "View All",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// ---------------- CATEGORY CARD ----------------

class CategoryCard extends StatelessWidget {
  final CategoryModel cat;

  const CategoryCard({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon(cat.icon), color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            cat.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String key) {
    switch (key) {
      case 'plumbing':
        return Icons.plumbing;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'carpenter':
        return Icons.carpenter;
      case 'ac_unit':
        return Icons.ac_unit;
      default:
        return Icons.miscellaneous_services;
    }
  }
}
