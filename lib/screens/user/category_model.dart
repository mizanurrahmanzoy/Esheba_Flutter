class CategoryModel {
  final String id;
  final String name;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CategoryModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'],
      icon: data['icon'],
    );
  }
}
