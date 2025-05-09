import 'package:flutter/material.dart';

class CatDashboard extends StatelessWidget {
  const CatDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cat Dashboard")),
      body: const Center(child: Text("All cats here")),
    );
  }
}