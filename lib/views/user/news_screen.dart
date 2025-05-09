import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<NewsItem> _newsItems = [
    NewsItem(
      title: 'New Cat Adoption Event',
      description: 'Join us this weekend for our special adoption event featuring cats of all ages.',
      date: 'May 10, 2025',
      imageUrl: 'https://example.com/cat1.jpg',
    ),
    NewsItem(
      title: 'Vaccinations Now Available',
      description: 'Free vaccinations for all registered cats are now available at our main center.',
      date: 'May 8, 2025',
      imageUrl: 'https://example.com/cat2.jpg',
    ),
    NewsItem(
      title: 'Volunteer Training Program',
      description: 'Sign up for our new volunteer training program and help care for cats in need.',
      date: 'May 5, 2025',
      imageUrl: 'https://example.com/cat3.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic here
          await Future.delayed(const Duration(seconds: 1));
          // In a real app, you would fetch new data here
        },
        child: _newsItems.isEmpty
            ? const Center(child: Text('No news available'))
            : ListView.builder(
          itemCount: _newsItems.length,
          itemBuilder: (context, index) {
            final item = _newsItems[index];
            return NewsCard(newsItem: item);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh news or navigate to specific news
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refreshing news...')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String date;
  final String imageUrl;

  NewsItem({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
  });
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;

  const NewsCard({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.photo,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        newsItem.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      newsItem.date,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  newsItem.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to full news article
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
                    child: const Text('Read More'),
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