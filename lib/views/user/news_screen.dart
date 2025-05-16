import 'package:flutter/material.dart';

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

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<NewsItem> _newsItems = [
    NewsItem(
      title: 'You Won\'t Believe What This Cat Did After Being Rescued!',
      description: 'A stray cat found in an abandoned building has shown an incredible talent that\'s leaving experts stunned and pet owners jealous.',
      date: 'May 15, 2025',
      imageUrl: 'https://example.com/shocking-cat.jpg',
      assetImage: 'assets/images/shocking-cat.jpg',
      tag: 'SHOCKING',
      tagColor: Colors.red,
    ),
    NewsItem(
      title: 'Secret Diet Has Cats Living Twice As Long, Vets Hate It!',
      description: 'A revolutionary feeding approach is changing everything we thought we knew about feline nutrition and longevity.',
      date: 'May 14, 2025',
      imageUrl: 'https://example.com/cat-diet.jpg',
      assetImage: 'assets/images/cat-diet.jpg',
      tag: 'EXCLUSIVE',
      tagColor: Colors.purple,
    ),
    NewsItem(
      title: '10 Signs Your Cat Might Actually Be Plotting Against You',
      description: 'New behavioral study reveals the hidden meanings behind common cat behaviors that might indicate sinister intentions.',
      date: 'May 12, 2025',
      imageUrl: 'https://example.com/plotting-cat.jpg',
      assetImage: 'assets/images/plotting-cat.jpg',
      tag: 'WARNING',
      tagColor: Colors.orange,
    ),
    NewsItem(
      title: 'Cat Inherits Millions From Mysterious Owner - The Reason Will Make You Cry',
      description: 'The heartbreaking story behind why a reclusive millionaire left their entire fortune to a stray cat they met just once.',
      date: 'May 10, 2025',
      imageUrl: 'https://example.com/rich-cat.jpg',
      assetImage: 'assets/images/rich-cat.jpg',
      tag: 'TEARJERKER',
      tagColor: Colors.blue,
    ),
    NewsItem(
      title: 'Scientists Discover Cats Can Actually Understand Everything You Say',
      description: 'Groundbreaking research reveals that cats comprehend human language at a level previously thought impossible - they\'re just choosing to ignore you.',
      date: 'May 8, 2025',
      imageUrl: 'https://example.com/smart-cat.jpg',
      assetImage: 'assets/images/smart-cat.jpg',
      tag: 'BREAKTHROUGH',
      tagColor: Colors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Implement refresh logic here
            await Future.delayed(const Duration(seconds: 1));
            // In a real app, you would fetch new data here
          },
          child: _newsItems.isEmpty
              ? const Center(child: Text('No news available'))
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              final item = _newsItems[index];
              return NewsCard(newsItem: item);
            },
          ),
        ),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  final String? assetImage;
  final String tag;
  final Color tagColor;

  NewsItem({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    this.assetImage,
    required this.tag,
    required this.tagColor,
  });
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;

  const NewsCard({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        shadowColor: colorScheme.shadow,
        color: colorScheme.surface.brighten(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to full news article when tapping anywhere on the card
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(newsItem.title),
                content: Text(
                  '${newsItem.description}\n\nThis is a placeholder for the full article content that would appear here in a complete implementation.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Image container with either asset image or gradient placeholder
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: _buildImage(colorScheme),
                  ),
                  // Tag chip with custom color
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: newsItem.tagColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        newsItem.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsItem.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsItem.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              newsItem.date,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Read full story',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildImage(ColorScheme colorScheme) {
    // Try to load from assets if available
    if (newsItem.assetImage != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Image.asset(
          newsItem.assetImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Fall back to placeholder if asset loading fails
            return _buildPlaceholder(colorScheme);
          },
        ),
      );
    } else {
      // Use placeholder if no asset image is specified
      return _buildPlaceholder(colorScheme);
    }
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.7),
            colorScheme.primary.darken(40).withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo,
          size: 60,
          color: colorScheme.onPrimary.withOpacity(0.7),
        ),
      ),
    );
  }
}