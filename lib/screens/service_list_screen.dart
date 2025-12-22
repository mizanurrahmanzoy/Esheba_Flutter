import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  String searchQuery = "";
  String selectedCategory = "All";
  String selectedLocation = "All";
  RangeValues priceRange = const RangeValues(0, 20000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Browse Services")),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search services...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),

          // FILTERS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: selectedCategory,
                items: const ["All", "Plumbing", "Electric", "Cleaning", "Repair"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
              ),
              DropdownButton<String>(
                value: selectedLocation,
                items: const ["All", "Dhaka", "Savar", "Mirpur", "Uttara"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedLocation = v!),
              ),
            ],
          ),

          // PRICE SLIDER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RangeSlider(
              values: priceRange,
              min: 0,
              max: 20000,
              divisions: 20,
              labels: RangeLabels(
                "${priceRange.start.toInt()}",
                "${priceRange.end.toInt()}",
              ),
              onChanged: (v) => setState(() => priceRange = v),
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("services")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No services available"));
                }

                final docs = snapshot.data!.docs;

                // SORT LOCALLY (safe)
                docs.sort((a, b) {
                  final aTime = a['createdAt'];
                  final bTime = b['createdAt'];
                  if (aTime == null || bTime == null) return 0;
                  return (bTime as Timestamp)
                      .compareTo(aTime as Timestamp);
                });

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final category =
                      (data['category'] ?? '').toString().toLowerCase();
                  // ignore: unused_local_variable
                  final location =
                      (data['location'] ?? '').toString().toLowerCase();
                  final price = (data['price'] ?? 0) as num;

                  final matchesSearch =
                      title.contains(searchQuery.toLowerCase()) ||
                      category.contains(searchQuery.toLowerCase());

                  final matchesCategory =
                      selectedCategory == "All" ||
                      data['category'] == selectedCategory;

                  final matchesLocation =
                      selectedLocation == "All" ||
                      data['location'] == selectedLocation;

                  final matchesPrice =
                      price >= priceRange.start &&
                      price <= priceRange.end;

                  return matchesSearch &&
                      matchesCategory &&
                      matchesLocation &&
                      matchesPrice;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No services match filters"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(data['title'] ?? 'No Title'),
                        subtitle: Text(
                          "${data['category'] ?? ''} • ${data['location'] ?? ''}\nTk ${data['price'] ?? 0}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                serviceId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
