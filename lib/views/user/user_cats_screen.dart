import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cat/cat_detail_screen.dart';
import 'add_cat_screen.dart';

// Extension to adjust color brightness - imported from user_dashboard.dart
extension ColorBrightness on Color {
  Color brighten(int amount) {
    return Color.fromARGB(
      alpha,
      (red + amount).clamp(0, 255),
      (green + amount).clamp(0, 255),
      (blue + amount).clamp(0, 255),
    );
  }

  Color darken(int amount) {
    return Color.fromARGB(
      alpha,
      (red - amount).clamp(0, 255),
      (green - amount).clamp(0, 255),
      (blue - amount).clamp(0, 255),
    );
  }
}

class CatsListScreen extends StatefulWidget {
  const CatsListScreen({super.key});

  @override
  State<CatsListScreen> createState() => _CatsListScreenState();
}

class _CatsListScreenState extends State<CatsListScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cats = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  bool _showAddOptions = false;

  @override
  void initState() {
    super.initState();
    _fetchCats();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAddOptions() {
    setState(() {
      _showAddOptions = !_showAddOptions;
      if (_showAddOptions) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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
    _toggleAddOptions(); // Hide the menu first
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
      body: Stack(
        children: [
          // Background design element
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? colors.surface.brighten(10)
                      : colors.surface.brighten(15),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.pets,
                                color: colors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'My Cats',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cats.isEmpty
                                ? 'Add your feline friends'
                                : '${_cats.length} cat${_cats.length == 1 ? '' : 's'} added',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      AddCatButton(
                        onTap: _toggleAddOptions,
                        colors: colors,
                        animationController: _animationController,
                      ),
                    ],
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colors.primary))
                    : _cats.isEmpty
                    ? _buildEmptyState(colors)
                    : RefreshIndicator(
                  onRefresh: _fetchCats,
                  color: colors.primary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _cats.length,
                      itemBuilder: (context, index) {
                        final cat = _cats[index];
                        return CatGridCard(
                          cat: cat,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CatDetailScreen(cat: cat),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Add options popup
          if (_showAddOptions)
            AddOptionsMenu(
              onAddNewCat: _addNewCat,
              onCancel: _toggleAddOptions,
              colors: colors,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cat paw print pattern
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(
              5,
                  (index) => Container(
                margin: const EdgeInsets.all(8),
                child: Icon(
                  Icons.pets,
                  size: index % 2 == 0 ? 40 : 30,
                  color: colors.primary.withOpacity(
                    index * 0.1 + 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No cats added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your feline companions to\ntrack their profiles and care',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewCat,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Cat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddCatButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colors;
  final AnimationController animationController;

  const AddCatButton({
    super.key,
    required this.onTap,
    required this.colors,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: animationController.value * 0.75, // 0.75 radians is about 45 degrees
              child: Icon(
                Icons.add,
                color: colors.onPrimary,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddOptionsMenu extends StatelessWidget {
  final VoidCallback onAddNewCat;
  final VoidCallback onCancel;
  final ColorScheme colors;

  const AddOptionsMenu({
    super.key,
    required this.onAddNewCat,
    required this.onCancel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel, // Close when tapping outside
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? colors.surface.brighten(10)
                  : colors.surface.brighten(15),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pets,
                      color: colors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add a New Cat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAddOption(
                  icon: Icons.add_circle_outline,
                  title: 'Create New Profile',
                  description: 'Add details about your cat',
                  onTap: onAddNewCat,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _buildAddOption(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR Code',
                  description: 'Import from cat collar tag',
                  onTap: () {
                    onCancel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR scanner coming soon!')),
                    );
                  },
                  colors: colors,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class CatGridCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final VoidCallback onTap;

  const CatGridCard({
    super.key,
    required this.cat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colors.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Use the same color brightening technique from the dashboard
      color: Theme.of(context).brightness == Brightness.light
          ? colors.surface.brighten(10)
          : colors.surface.brighten(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cat image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cat['image_url'] != null && cat['image_url'].isNotEmpty)
                    Image.network(
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
                        return _buildPlaceholderImage(colors);
                      },
                    )
                  else
                    _buildPlaceholderImage(colors),

                  // Gradient overlay for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cat info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.cake,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${cat['age'] ?? 0} ${int.parse(cat['age'].toString()) == 1 ? 'year' : 'years'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildCatTag(context, cat['breed'] ?? 'Unknown'),
                        const SizedBox(width: 6),
                        _buildCatTag(context, cat['gender'] ?? 'Unknown'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colors) {
    return Container(
      color: colors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 40,
          color: colors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCatTag(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}