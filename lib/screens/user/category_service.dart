import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esheba_fixian/screens/user/category_model.dart';
// import '../models/category_model.dart';

class CategoryService {
  static Future<List<CategoryModel>> getCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return snap.docs
        .map((d) => CategoryModel.fromFirestore(d.id, d.data()))
        .toList();
  }
}
