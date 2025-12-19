import 'package:flutter/material.dart';

class ChooseAccountTypeScreen extends StatelessWidget {
  const ChooseAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Account")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Register as Customer"),
              onPressed: () {
                Navigator.pushNamed(context, '/register-customer');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.build),
              label: const Text("Register as Service Provider"),
              onPressed: () {
                Navigator.pushNamed(context, '/register-provider');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
