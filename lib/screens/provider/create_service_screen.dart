import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/category_service.dart';
import '../../services/usage_service.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();

  List<String> categories = [];
  String? selectedCategory;

  bool isLoading = false;
  bool isCategoryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final data = await CategoryService.getCategories();
    setState(() {
      categories = data;
      selectedCategory = categories.isNotEmpty ? categories.first : null;
      isCategoryLoading = false;
    });
  }

  Future<void> submitService() async {
    FocusScope.of(context).unfocus();

    try {
      final allowed = await UsageService.canPostService();
      if (!allowed) {
        _showUpgradeDialog();
        return;
      }

      if (selectedCategory == null ||
          titleController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty) {
        _showError("Please fill all required fields");
        return;
      }

      final price = int.tryParse(priceController.text.trim());
      if (price == null) {
        _showError("Invalid price");
        return;
      }

      setState(() => isLoading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('services').add({
        'providerId': uid,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategory,
        'price': price,
        'location': locationController.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        /// hourly rate
        'isHourly': false,
        'hourlyRate': 0,
        /// order count
        'orderCount': 0,
      });

      await UsageService.increasePostCount();

      if (!mounted) return;
      setState(() => isLoading = false);

      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError("Something went wrong. Please try again.");
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Service Posted 🎉"),
        content: const Text(
          "Your service has been successfully published and is now visible to customers.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Post Limit Reached"),
        content: const Text(
          "Free providers can post only 2 services.\nUpgrade to Premium to post more.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium_upgrade');
            },
            child: const Text("Upgrade"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCategoryLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color.fromARGB(255, 0, 164, 214), Color.fromARGB(255, 147, 226, 0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const FlexibleSpaceBar(
                      title: Text("Post a Service",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _formCard(),
                      const SizedBox(height: 24),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: submitService,
                                icon: const Icon(Icons.publish),
                                label: const Text("Publish Service"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _formCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(
              controller: titleController,
              label: "Service Title",
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 12),

            _input(
              controller: descriptionController,
              label: "Description",
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              decoration: const InputDecoration(
                labelText: "Category",
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 12),

            _input(
              controller: priceController,
              label: "Price (Tk)",
              icon: Icons.payments_outlined,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),

            _input(
              controller: locationController,
              label: "Location",
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
