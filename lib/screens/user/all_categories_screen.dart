import 'package:esheba_fixian/screens/user/category_model.dart';
import 'package:flutter/material.dart';
// import '../models/category_model.dart';


class AllCategoriesScreen extends StatelessWidget {
  final List<CategoryModel> categories;

  const AllCategoriesScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Services")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (_, index) {
          final cat = categories[index];
          return CategoryCard(cat: cat);
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final CategoryModel cat;

  const CategoryCard({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
