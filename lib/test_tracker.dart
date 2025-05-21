import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  String result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              decoration: InputDecoration(labelText: 'Goal'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _pagesController,
              decoration: InputDecoration(labelText: 'Pages Read'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                final goalText = _goalController.text.trim();
                final pagesText = _pagesController.text.trim();
                final goal = int.tryParse(goalText.replaceAll(RegExp(r'[^0-9]'), ''));
                final pages = int.tryParse(pagesText.replaceAll(RegExp(r'[^0-9]'), ''));
                if (goal == null || pages == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen geçerli bir sayı giriniz!')),
                  );
                  return;
                }
                setState(() {
                  result = (pages >= goal) ? '✓' : '✗';
                });
              },
              child: Text('Save'),
            ),
            SizedBox(height: 20),
            Text('Result: $result', style: TextStyle(fontSize: 32)),
          ],
        ),
      ),
    );
  }
} 