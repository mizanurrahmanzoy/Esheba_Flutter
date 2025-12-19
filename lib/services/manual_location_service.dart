import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManualLocationResult {
  final String address;
  final double lat;
  final double lng;

  ManualLocationResult({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class ManualLocationService {
  static Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.length < 3) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query&format=json&addressdetails=1&limit=5',
    );

    final res = await http.get(
      url,
      headers: {'User-Agent': 'esheba-fixian-app'},
    );

    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);

    return data
        .map((e) => {
              'name': e['display_name'],
              'lat': double.parse(e['lat']),
              'lng': double.parse(e['lon']),
            })
        .toList();
  }

  static Future<ManualLocationResult?> pickLocation(
      BuildContext context) async {
    return showDialog<ManualLocationResult>(
      context: context,
      builder: (_) => const _LocationSearchDialog(),
    );
  }
}

/* ---------------- SEARCH DIALOG ---------------- */

class _LocationSearchDialog extends StatefulWidget {
  const _LocationSearchDialog();

  @override
  State<_LocationSearchDialog> createState() =>
      _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final ctrl = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  void search(String q) async {
    setState(() => loading = true);
    results = await ManualLocationService.search(q);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search location"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: "Type area, city...",
            ),
            onChanged: search,
          ),
          const SizedBox(height: 12),
          if (loading)
            const CircularProgressIndicator()
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final r = results[i];
                  return ListTile(
                    title: Text(r['name']),
                    onTap: () {
                      Navigator.pop(
                        context,
                        ManualLocationResult(
                          address: r['name'],
                          lat: r['lat'],
                          lng: r['lng'],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
