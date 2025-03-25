import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Charger les données utilisateur
    try {
      // Placeholder pour le moment
    } catch (e) {
      // Gérer erreur
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sunday Sport Club')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(child: Text('Bienvenue sur Sunday Sport Club')),
    );
  }
}
