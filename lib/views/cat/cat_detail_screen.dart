import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatDetailScreen extends StatelessWidget {
  final Map<String, dynamic> cat;

  const CatDetailScreen({
    super.key,
    required this.cat,
  });

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
        content: Text('Are you sure you want to delete ${cat['name']}?'),
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
            child: Text(
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
          .eq('id', cat['id']);

      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (context.mounted) {
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
                    tag: 'cat_image_${cat['id']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colors.primary.withOpacity(0.3),
                      backgroundImage: cat['image_url'] != null &&
                          cat['image_url'].isNotEmpty
                          ? NetworkImage(cat['image_url'])
                          : null,
                      child: cat['image_url'] == null ||
                          cat['image_url'].isEmpty
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
                    cat['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  if (cat['breed'] != null && cat['breed'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        cat['breed'],
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
                color: colors.surface,
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
                      _infoRow("Name", cat['name'], colors),
                      _infoRow("Breed", cat['breed'], colors),
                      _infoRow(
                          "Age",
                          '${cat['age']} ${int.parse(cat['age'].toString()) == 1 ? 'year' : 'years'} old',
                          colors
                      ),
                      _infoRow("Gender", cat['gender'], colors),
                      _infoRow("Color", cat['color'], colors),
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