import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cat/cat_detail_screen.dart';
import 'add_cat_screen.dart';

class CatsListScreen extends StatefulWidget {
  const CatsListScreen({super.key});

  @override
  State<CatsListScreen> createState() => _CatsListScreenState();
}

class _CatsListScreenState extends State<CatsListScreen> {
  List<Map<String, dynamic>> _cats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCats();
  }

  Future<void> _fetchCats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _cats = [];
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('cats')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cats = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cats: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addNewCat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCatScreen()),
    );

    if (result == true) {
      _fetchCats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : _cats.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: colors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No cats added yet',
              style: TextStyle(
                fontSize: 18,
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewCat,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Cat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchCats,
        color: colors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _cats.length,
          itemBuilder: (context, index) {
            final cat = _cats[index];
            return CatCard(
              cat: cat,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CatDetailScreen(cat: cat),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _cats.isNotEmpty
          ? FloatingActionButton(
        onPressed: _addNewCat,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class CatCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final VoidCallback onTap;

  const CatCard({
    super.key,
    required this.cat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cat image
            if (cat['image_url'] != null && cat['image_url'].isNotEmpty)
              SizedBox(
                height: 180,
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
                          size: 40,
                          color: colors.primary.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                color: colors.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 40,
                    color: colors.primary.withOpacity(0.5),
                  ),
                ),
              ),

            // Cat info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoChip(
                        context,
                        cat['breed'] ?? 'Unknown breed',
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        context,
                        cat['gender'] ?? 'Unknown gender',
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        context,
                        '${cat['age'] ?? 0} ${int.parse(cat['age'].toString()) == 1 ? 'year' : 'years'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}