import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cat/cat_main.dart';
import 'add_cat_screen.dart';
import 'add_qr_cat_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';


// Extension to adjust color brightness
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

// Enhanced CatsDataCache with preloading capabilities
class CatsDataCache {
  final ValueNotifier<List<Map<String, dynamic>>> catsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final SupabaseClient _supabase = Supabase.instance.client;
  final CatCacheManager _cacheManager = CatCacheManager();
  bool _preloadingImages = false;

  Future<void> fetchCats({bool forceRefresh = false}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // Handle unauthenticated state
        debugPrint('No user logged in, cannot fetch cats');
        catsNotifier.value = [];
        return;
      }

      final response = await _supabase
          .from('cats')
          .select()
          .eq('user_id', currentUser.id)
          .order('name');


      final List<Map<String, dynamic>> cats =
      (response as List).map((item) => item as Map<String, dynamic>).toList();

      catsNotifier.value = cats;

      // Start preloading images after data is fetched
      if (!_preloadingImages) {
        _preloadingImages = true;
        _preloadImages(cats);
      }
    } catch (e) {
      debugPrint('Error fetching cats: $e');
      rethrow;
    }
  }

  // Preload images in the background
  Future<void> _preloadImages(List<Map<String, dynamic>> cats) async {
    for (final cat in cats) {
      if (cat['image_url'] != null && cat['image_url'].isNotEmpty) {
        try {
          // Generate a stable cache key based on ID and last update time
          final cacheKey = '${cat['id']}_${cat['updated_at'] ?? ''}';

          // Check if image already exists in cache
          final fileInfo = await _cacheManager.getFileFromCache(cacheKey);

          // If not cached, download it in background
          if (fileInfo == null) {
            _cacheManager.getSingleFile(
              cat['image_url'],
              key: cacheKey,
            ).catchError((e) {
              debugPrint('Background preload error for cat ${cat['id']}: $e');
            });
          }
        } catch (e) {
          // Don't let preloading errors disrupt the app
          debugPrint('Preload error: $e');
        }
      }
    }
    _preloadingImages = false;
  }

  void updateCat(Map<String, dynamic> updatedCat) {
    final currentCats = List<Map<String, dynamic>>.from(catsNotifier.value);
    final index = currentCats.indexWhere((cat) => cat['id'] == updatedCat['id']);

    if (index != -1) {
      currentCats[index] = updatedCat;
      catsNotifier.value = currentCats;
    }
  }
}

// Improved CatCacheManager with persistent storage
class CatCacheManager extends CacheManager {
  static const key = 'catAppCacheKey';
  static const Duration cacheDuration = Duration(days: 14); // Extended cache duration

  static final CatCacheManager _instance = CatCacheManager._();
  factory CatCacheManager() => _instance;

  CatCacheManager._() : super(Config(
    key,
    stalePeriod: cacheDuration,
    maxNrOfCacheObjects: 200, // Increased cache size
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(),
  ));

  // Get a stable cache key for an image
  static String getCacheKey(Map<String, dynamic> cat) {
    return '${cat['id']}_${cat['updated_at'] ?? ''}';
  }
}

class CatsListScreen extends StatefulWidget {
  const CatsListScreen({super.key});

  @override
  State<CatsListScreen> createState() => _CatsListScreenState();
}

class _CatsListScreenState extends State<CatsListScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _catsCache = CatsDataCache();
  bool _isLoading = true;
  late AnimationController _animationController;
  bool _showAddOptions = false;
  final ScrollController _scrollController = ScrollController();

  // Keep this state alive when navigating
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCats();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add listener for pagination or lazy loading if needed
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Implement pagination logic here if needed
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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

  Future<void> _loadCats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _catsCache.fetchCats();

      if (mounted) {
        setState(() {
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

  Future<void> _refreshCats() async {
    try {
      // Clear the image cache only when explicitly refreshing
      await CatCacheManager().emptyCache();
      await _catsCache.fetchCats(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cat data refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing cats: ${e.toString()}')),
        );
      }
    }
  }

  // Modified to show dialog instead of directly navigating
  Future<void> _showAddCatOptions() async {
    _toggleAddOptions(); // Show the options dialog
  }

  Future<void> _addNewCat() async {
    _toggleAddOptions(); // Hide the menu first
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCatScreen()),
    );

    if (result == true) {
      // Force refresh to get the newly added cat
      _refreshCats();
    }
  }

  Future<void> _addCatViaQrCode() async {
    _toggleAddOptions(); // Hide the menu first
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddQrCatScreen()),
    );

    if (result == true) {
      // Force refresh to get the newly added cat
      _refreshCats();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _catsCache.catsNotifier,
                    builder: (context, cats, _) {
                      return Row(
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
                                cats.isEmpty
                                    ? 'Add your feline friends'
                                    : '${cats.length} cat${cats.length == 1 ? '' : 's'} added',
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
                      );
                    },
                  ),
                ),
              ),

              // Main content area - optimize with better state management
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colors.primary))
                    : ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _catsCache.catsNotifier,
                  builder: (context, cats, _) {
                    return cats.isEmpty
                        ? _buildEmptyState(colors)
                        : RefreshIndicator(
                      onRefresh: _refreshCats,
                      color: colors.primary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 16, bottom: 80),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: cats.length,
                          itemBuilder: (context, index) {
                            final cat = cats[index];
                            return OptimizedCatGridCard(
                              cat: cat,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CatMain(cat: cat),
                                  ),
                                ).then((updatedCat) {
                                  if (updatedCat != null && updatedCat is Map<String, dynamic>) {
                                    _catsCache.updateCat(updatedCat);
                                    // Also refresh the list to get freshest data
                                    _refreshCats();
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Add options popup
          if (_showAddOptions)
            AddOptionsMenu(
              onAddNewCat: _addNewCat,
              onAddCatViaQr: _addCatViaQrCode, // Add new parameter for QR code
              onCancel: _toggleAddOptions,
              colors: colors,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return RefreshIndicator(
      onRefresh: _refreshCats, // Add refresh capability to empty state too
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
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
                  onPressed: _showAddCatOptions, // Changed to show dialog instead of direct navigation
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
          ),
        ],
      ),
    );
  }
}

// New optimized card with Hero animations and better caching
class OptimizedCatGridCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final VoidCallback onTap;

  const OptimizedCatGridCard({
    super.key,
    required this.cat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cacheKey = CatCacheManager.getCacheKey(cat);

    return Card(
      elevation: 2,
      shadowColor: colors.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.light
          ? colors.surface.brighten(10)
          : colors.surface.brighten(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cat image with Hero animation for smooth transitions
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cat['image_url'] != null && cat['image_url'].isNotEmpty)
                    Hero(
                      tag: 'cat_image_${cat['id']}',
                      child: CachedNetworkImage(
                        imageUrl: cat['image_url'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildImagePlaceholder(context, colors),
                        errorWidget: (context, url, error) {
                          debugPrint('Error loading image: $error');
                          return _buildPlaceholderImage(colors);
                        },
                        // Use stable cache key based on cat ID and update time
                        cacheKey: cacheKey,
                        memCacheWidth: 300,
                        memCacheHeight: 300,
                        cacheManager: CatCacheManager(),
                        // Use fadeInDuration for smoother loading experience
                        fadeInDuration: const Duration(milliseconds: 300),
                      ),
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

  // Improved placeholder with shimmer-like effect when loading
  Widget _buildImagePlaceholder(BuildContext context, ColorScheme colors) {
    return Container(
      color: colors.primary.withOpacity(0.05),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
          ),
          Opacity(
            opacity: 0.3,
            child: Icon(
              Icons.pets,
              size: 40,
              color: colors.primary,
            ),
          ),
        ],
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

// Original AddCatButton class remains the same
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

// Updated AddOptionsMenu class with fixed navigation for QR code option
class AddOptionsMenu extends StatelessWidget {
  final VoidCallback onAddNewCat;
  final VoidCallback onAddCatViaQr; // New callback for QR code
  final VoidCallback onCancel;
  final ColorScheme colors;

  const AddOptionsMenu({
    super.key,
    required this.onAddNewCat,
    required this.onAddCatViaQr, // New parameter
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
                  onTap: onAddCatViaQr, // Use the new callback directly
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