import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditServiceScreen extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> data;

  const EditServiceScreen({
    super.key,
    required this.serviceId,
    required this.data,
  });

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController priceCtrl;
  late bool isActive;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.data['title']);
    descriptionCtrl = TextEditingController(text: widget.data['description'] ?? '');
    priceCtrl = TextEditingController(text: widget.data['price'].toString());
    isActive = widget.data['isActive'] == true;
  }

  Future<void> save() async {
    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .update({
      'title': titleCtrl.text.trim(),
      'description': descriptionCtrl.text.trim(),
      'price': int.tryParse(priceCtrl.text) ?? 0,
      'isActive': isActive,
    });

    if (!mounted) return;
    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Service")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Service Title"),
            ),
            
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isActive,
              title: const Text("Service Active"),
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 16),
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: save,
                      child: const Text("Save Changes"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
