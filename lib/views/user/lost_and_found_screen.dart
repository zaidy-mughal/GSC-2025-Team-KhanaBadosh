import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'lost_cat_details_screen.dart'; // Add this import


// Extension to adjust color brightness - same as in user_cats_screen.dart
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

// Cache manager for lost cats images
class LostCatCacheManager extends CacheManager {
  static const key = 'lostCatCacheKey';
  // Updated cache duration from 7 days to 1 day
  static const Duration cacheDuration = Duration(days: 1);

  static final LostCatCacheManager _instance = LostCatCacheManager._();
  factory LostCatCacheManager() => _instance;

  LostCatCacheManager._() : super(Config(
    key,
    stalePeriod: cacheDuration,
    maxNrOfCacheObjects: 100,
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(),
  ));

  // Get a stable cache key for an image
  static String getCacheKey(Map<String, dynamic> cat) {
    return '${cat['id']}_${cat['updated_at'] ?? ''}';
  }
}

// Data manager for lost cats
class LostCatsDataManager {
  final ValueNotifier<List<Map<String, dynamic>>> lostCatsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final SupabaseClient _supabase = Supabase.instance.client;
  final _cacheManager = LostCatCacheManager();

  Future<void> fetchLostCats({String? searchQuery}) async {
    isLoadingNotifier.value = true;

    try {
      var query = _supabase
          .from('cats')
          .select()
          .eq('status', 'True'); // Changed from is_lost to status

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final response = await query.order('reported_lost_at', ascending: false);

      final List<Map<String, dynamic>> lostCats =
      (response as List).map((item) => item as Map<String, dynamic>).toList();

      lostCatsNotifier.value = lostCats;

      // Preload images in background
      _preloadImages(lostCats);
    } catch (e) {
      debugPrint('Error fetching lost cats: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> _preloadImages(List<Map<String, dynamic>> cats) async {
    for (final cat in cats) {
      if (cat['image_url'] != null && cat['image_url'].isNotEmpty) {
        try {
          final cacheKey = LostCatCacheManager.getCacheKey(cat);
          final fileInfo = await _cacheManager.getFileFromCache(cacheKey);

          if (fileInfo == null) {
            _cacheManager.getSingleFile(
              cat['image_url'],
              key: cacheKey,
            ).catchError((e) {
              debugPrint('Background preload error for cat ${cat['id']}: $e');
            });
          }
        } catch (e) {
          debugPrint('Preload error: $e');
        }
      }
    }
  }
}

class LostAndFoundScreen extends StatefulWidget {
  const LostAndFoundScreen({super.key});

  @override
  State<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _LostAndFoundScreenState extends State<LostAndFoundScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final LostCatsDataManager _dataManager = LostCatsDataManager();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLostCats();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _loadLostCats(searchQuery: _searchQuery);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLostCats({String? searchQuery}) async {
    await _dataManager.fetchLostCats(searchQuery: searchQuery);
  }

  Future<void> _refreshLostCats() async {
    await _loadLostCats(searchQuery: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background design element (similar to the cats screen)
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withOpacity(0.1),
              ),
            ),
          ),

          Column(
            children: [
              // Custom App Bar with header section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                color: colors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lost & Found',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tab Bar - Modified to cover the whole tab
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          // Indicator now fills the whole tab
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: colors.primary,
                          ),
                          dividerColor: Colors.transparent,
                          // Removed the built-in divider by setting indicatorColor to transparent
                          indicatorColor: Colors.transparent,
                          labelColor: colors.onPrimary,
                          unselectedLabelColor: colors.onSurface.withOpacity(0.7),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          tabs: const [
                            Tab(text: 'Lost'),
                            Tab(text: 'Found'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Tab content - Added NeverScrollableScrollPhysics
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Lost Cats Tab
                    _buildLostCatsTab(colors),

                    // Found Tab with QR Scanner
                    _buildFoundTab(colors),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLostCatsTab(ColorScheme colors) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search lost cats...',
              prefixIcon: Icon(
                Icons.search,
                color: colors.primary,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? colors.surface.brighten(5)
                  : colors.surface.brighten(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),
        ),

        // Lost Cats List
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _dataManager.isLoadingNotifier,
            builder: (context, isLoading, _) {
              if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primary),
                );
              }

              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _dataManager.lostCatsNotifier,
                builder: (context, lostCats, _) {
                  if (lostCats.isEmpty) {
                    return _buildEmptyLostState(colors);
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshLostCats,
                    color: colors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: lostCats.length,
                      itemBuilder: (context, index) {
                        final cat = lostCats[index];
                        return LostCatCard(cat: cat, colors: colors);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoundTab(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top part with illustration
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: colors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),

          // Text
          Text(
            'Found a Cat?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Scan the QR code on their collar tag to help reunite them with their owner',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Scan button
          ElevatedButton.icon(
            onPressed: () {
              // Show snackbar for now since scanner isn't implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Scanner coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLostState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 70,
            color: colors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'No Lost Cats Reported'
                : 'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isEmpty
                  ? 'All cats are safe at home!'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LostCatCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final ColorScheme colors;

  const LostCatCard({
    super.key,
    required this.cat,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final cacheKey = LostCatCacheManager.getCacheKey(cat);
    final lostDate = cat['reported_lost_at'] != null
        ? DateTime.parse(cat['reported_lost_at'])
        : DateTime.now();
    final daysLost = DateTime.now().difference(lostDate).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shadowColor: colors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: Theme.of(context).brightness == Brightness.light
            ? colors.surface.brighten(10)
            : colors.surface.brighten(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate to lost cat details screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LostCatDetailScreen(cat: cat),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cat image
              SizedBox(
                width: 120,
                height: 120,
                child: cat['image_url'] != null && cat['image_url'].isNotEmpty
                    ? Hero(
                  tag: 'lost_cat_${cat['id']}',
                  child: CachedNetworkImage(
                    imageUrl: cat['image_url'],
                    fit: BoxFit.cover,
                    cacheKey: cacheKey,
                    placeholder: (context, url) => _buildPlaceholder(colors),
                    errorWidget: (context, url, error) => _buildPlaceholder(colors),
                    cacheManager: LostCatCacheManager(),
                  ),
                )
                    : _buildPlaceholder(colors),
              ),

              // Cat details - Wrap in an Expanded to ensure proper layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cat details container - Removed extra padding that was causing space
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 12,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LOST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                daysLost == 0
                                    ? 'Since Today'
                                    : '$daysLost ${daysLost == 1 ? 'day' : 'days'} ago',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Cat name
                          Text(
                            cat['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Cat details
                          Row(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${cat['breed'] ?? 'Unknown'}, ${cat['age'] ?? '?'} ${int.parse(cat['age']?.toString() ?? '1') == 1 ? 'year' : 'years'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4), // Reduced space here

                          // Location details
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cat['last_seen_location'] ?? 'Location unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colors) {
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
}