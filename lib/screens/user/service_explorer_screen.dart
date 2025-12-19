import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/service_detail_screen.dart';
import 'package:flutter/material.dart';

class ServiceExplorerScreen extends StatefulWidget {
  const ServiceExplorerScreen({super.key});

  @override
  State<ServiceExplorerScreen> createState() => _ServiceExplorerScreenState();
}

class _ServiceExplorerScreenState extends State<ServiceExplorerScreen> {
  String searchText = '';
  String? selectedCategory;
  RangeValues priceRange = const RangeValues(0, 5000);
  bool newestFirst = true;

  Query get query {
    Query q = FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true);

    if (selectedCategory != null) {
      q = q.where('category', isEqualTo: selectedCategory);
    }

    q = q.orderBy('createdAt', descending: newestFirst);

    return q;
  }

  void openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Filter Services",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                // CATEGORY
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  hint: const Text("Select Category"),
                  items: const [
                    DropdownMenuItem(
                      value: 'AC Service',
                      child: Text('AC Service'),
                    ),
                    DropdownMenuItem(
                      value: 'Plumbing',
                      child: Text('Plumbing'),
                    ),
                    DropdownMenuItem(
                      value: 'Electrical',
                      child: Text('Electrical'),
                    ),
                  ],
                  onChanged: (v) => setSheetState(() => selectedCategory = v),
                ),

                const SizedBox(height: 12),

                // PRICE RANGE
                RangeSlider(
                  min: 0,
                  max: 5000,
                  divisions: 10,
                  values: priceRange,
                  labels: RangeLabels(
                    priceRange.start.round().toString(),
                    priceRange.end.round().toString(),
                  ),
                  onChanged: (v) => setSheetState(() => priceRange = v),
                ),

                const SizedBox(height: 12),

                // POST DURATION
                SwitchListTile(
                  title: const Text("Newest First"),
                  value: newestFirst,
                  onChanged: (v) => setSheetState(() => newestFirst = v),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Apply Filters"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool priceMatch(num price) {
    return price >= priceRange.start && price <= priceRange.end;
  }

  bool searchMatch(String title) {
    return title.toLowerCase().contains(searchText.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Services"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search services...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => searchText = v),
            ),
          ),

          // 📋 SERVICE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return priceMatch(data['price']) &&
                      searchMatch(data['title']);
                }).toList();

                if (services.isEmpty) {
                  return const Center(child: Text("No services found"));
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, i) {
                    final data = services[i].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(data['title']),
                        subtitle: Text(
                          "${data['category']} • ৳${data['price']}",
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                serviceId: services[i].id,
                                data: {},
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
          ),
        ],
      ),
    );
  }
}
