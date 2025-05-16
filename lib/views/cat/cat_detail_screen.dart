import 'package:cat_app/views/auth/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_cat_screen.dart';
import '../user/user_main.dart';

class CatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cat;
  final Function() onRefresh;

  const CatDetailScreen({
    super.key,
    required this.cat,
    required this.onRefresh,
  });

  @override
  State<CatDetailScreen> createState() => _CatDetailScreenState();
}

class _CatDetailScreenState extends State<CatDetailScreen> {
  late Map<String, dynamic> _catData;

  @override
  void initState() {
    super.initState();
    // Initialize with the data passed from parent
    _catData = Map<String, dynamic>.from(widget.cat);
  }

  Future<void> _refreshCatData() async {
    try {
      // Fetch the latest cat data from Supabase
      final response = await Supabase.instance.client
          .from('cats')
          .select()
          .eq('id', _catData['id'])
          .single();

      // Update the state with fresh data
      setState(() {
        _catData = response;
      });

      // Also refresh the parent screen's data
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing cat data: ${e.toString()}')),
        );
      }
    }
  }

  Widget _infoRow(String label, String? value, ColorScheme colors, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not provided',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: multiLine ? 5 : 1,
            overflow: multiLine ? TextOverflow.ellipsis : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.onSurface.withOpacity(0.2)),
        ],
      ),
    );
  }

  Future<void> _deleteCat(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cat'),
        content: Text('Are you sure you want to delete ${_catData['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('cats')
          .delete()
          .eq('id', _catData['id']);

      if (mounted) {
        // Call parent's refresh function
        widget.onRefresh();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const UserMain(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting cat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary.withOpacity(0.1),
        iconTheme: IconThemeData(color: colors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCatScreen(cat: _catData),
                ),
              ).then(
                      (value) {
                    if (value == true) {
                      // Refresh both this screen and parent
                      _refreshCatData();
                    }
                  });
            },
            tooltip: 'Edit Cat',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteCat(context),
            tooltip: 'Delete Cat',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with image
            Container(
              width: double.infinity,
              color: colors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Hero(
                    tag: 'cat_image_${_catData['id']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colors.primary.withOpacity(0.3),
                      backgroundImage: _catData['image_url'] != null &&
                          _catData['image_url'].isNotEmpty
                          ? NetworkImage(_catData['image_url'])
                          : null,
                      child: _catData['image_url'] == null ||
                          _catData['image_url'].isEmpty
                          ? Icon(
                        Icons.pets,
                        size: 60,
                        color: colors.primary,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _catData['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  if (_catData['breed'] != null && _catData['breed'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _catData['breed'],
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Cat information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                color: colors.surface.brighten(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cat Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow("Name", _catData['name'], colors),
                      _infoRow("Breed", _catData['breed'], colors),
                      _infoRow(
                          "Age",
                          '${_catData['age']} ${int.parse(_catData['age'].toString()) == 1 ? 'year' : 'years'} old',
                          colors
                      ),
                      _infoRow("Gender", _catData['gender'], colors),
                      _infoRow("Color", _catData['color'], colors),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}