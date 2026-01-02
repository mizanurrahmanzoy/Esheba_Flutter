import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool loading = true;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> popularServices = [];
  List<Map<String, dynamic>> latestServices = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);

    final now = DateTime.now();

    // Categories
    final catSnap = await FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    categories = catSnap.docs.map((d) {
      final data = d.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      return {...data, 'isNew': now.difference(createdAt).inDays <= 7};
    }).toList();

    // Popular services
    final popSnap = await FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('orderCount', descending: true)
        .limit(6)
        .get();

    popularServices = popSnap.docs.map((d) => d.data()).toList();

    // Latest services
    final latestSnap = await FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(6)
        .get();

    latestServices = latestSnap.docs.map((d) => d.data()).toList();

    setState(() => loading = false);
  }

  // ===================== SKELETONS =====================

  Widget categorySkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white),
            const SizedBox(height: 6),
            Container(height: 10, width: 40, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget serviceSkeleton() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(),
                const SizedBox(height: 20),
                bannerSlider(),
                const SizedBox(height: 20),

                sectionTitle("Categories"),
                loading ? categorySkeleton() : categoryGrid(),

                const SizedBox(height: 24),
                sectionTitle("Popular Services"),
                loading ? serviceSkeleton() : popularServiceList(),

                const SizedBox(height: 24),
                sectionTitle("New Services"),
                loading ? serviceSkeleton() : latestServiceList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== COMPONENTS =====================

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ===================== WIDGETS =====================
  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Cleaning House",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.notifications_none),
        ),
      ],
    );
  }

  //banner slider
  Widget bannerSlider() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return serviceSkeleton();

        return CarouselSlider(
          items: snap.data!.docs.map((d) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: d['image'],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            enlargeCenterPage: true,
          ),
        );
      },
    );
  }

  Widget categoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (_, i) {
        final c = categories[i];
        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.withOpacity(.12),
                  child: CachedNetworkImage(imageUrl: c['icon'], width: 28),
                ),
                if (c['isNew'])
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "NEW",
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              c['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget popularServiceList() {
    return buildServiceList(popularServices);
  }

  Widget latestServiceList() {
    return buildServiceList(latestServices);
  }

  Widget buildServiceList(List services) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = services[i];
          return Container(
            width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "৳ ${s['price']}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
