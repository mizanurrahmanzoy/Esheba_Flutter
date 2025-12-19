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
    debugPrint("🔥 submitService() called");

    FocusScope.of(context).unfocus();

    try {
      debugPrint("⏳ Checking usage limit...");
      final allowed = await UsageService.canPostService();
      debugPrint("✅ canPostService = $allowed");

      if (!allowed) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Post Limit Reached"),
            content: const Text(
              "Free providers can post only 2 services.\nUpgrade to Premium.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      if (selectedCategory == null) {
        debugPrint("❌ selectedCategory is NULL");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Category not selected")));
        return;
      }

      if (titleController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty) {
        debugPrint("❌ Required fields missing");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
        return;
      }

      final price = int.tryParse(priceController.text.trim());
      if (price == null) {
        debugPrint("❌ Price parse failed");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid price")));
        return;
      }

      setState(() => isLoading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      debugPrint("👤 Provider UID = $uid");

      await FirebaseFirestore.instance.collection('services').add({
        'providerId': uid,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategory,
        'price': price,
        'location': locationController.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Service posted successfully");

      await UsageService.increasePostCount();

      if (!mounted) return;
      setState(() => isLoading = false);

      /// 🎉 SUCCESS DIALOG
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Success 🎉"),
          content: const Text("Your service has been posted successfully."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e, s) {
      debugPrint("🔥 ERROR in submitService: $e");
      debugPrint(s.toString());

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Service")),
      body: isCategoryLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Service Title",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val),
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price (Tk)"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: "Location"),
                  ),
                  const SizedBox(height: 24),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: submitService,
                            child: const Text("Post Service"),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
