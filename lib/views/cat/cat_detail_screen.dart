import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatDetailScreen extends StatelessWidget {
  final Map<String, dynamic> cat;

  const CatDetailScreen({
    super.key,
    required this.cat,
  });

  Widget _infoRow(String label, String? value, ColorScheme colors) {
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
        title: Text(
          cat['name'] ?? 'Cat Details',
          style: TextStyle(color: colors.onPrimary),
        ),
        backgroundColor: colors.primary,
        iconTheme: IconThemeData(color: colors.onPrimary),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cat image header
            if (cat['image_url'] != null && cat['image_url'].isNotEmpty)
              Hero(
                tag: 'cat-image-${cat['id']}',
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.network(
                    cat['image_url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: colors.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colors.primary.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 60,
                            color: colors.primary.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                color: colors.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 70,
                    color: colors.primary.withOpacity(0.5),
                  ),
                ),
              ),

            // Cat name header
            Container(
              width: double.infinity,
              color: colors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    cat['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['breed'] ?? 'Unknown breed',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Cat details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      _infoRow('Name', cat['name'], colors),
                      _infoRow('Breed', cat['breed'], colors),
                      _infoRow(
                          'Age',
                          '${cat['age']} ${int.parse(cat['age'].toString()) == 1 ? 'year' : 'years'} old',
                          colors
                      ),
                      _infoRow('Gender', cat['gender'], colors),
                      _infoRow('Color', cat['color'], colors),
                      if (cat['created_at'] != null)
                        _infoRow(
                            'Added on',
                            DateTime.parse(cat['created_at']).toString().split('.')[0],
                            colors
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}