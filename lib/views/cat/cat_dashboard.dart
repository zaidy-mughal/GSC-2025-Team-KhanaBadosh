import 'package:flutter/material.dart';

class CatDashboard extends StatefulWidget {
  final Map<String, dynamic> cat;
  final Function(int) onNavigateToTab;

  const CatDashboard({
    super.key,
    required this.cat,
    required this.onNavigateToTab,
  });

  @override
  State<CatDashboard> createState() => _CatDashboardState();
}

class _CatDashboardState extends State<CatDashboard> with AutomaticKeepAliveClientMixin {
  // Keep this state alive when navigating
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cat profile header
            _buildProfileHeader(colors),

            // Stats overview section
            _buildStatsOverview(colors),

            // Quick action buttons
            _buildQuickActions(colors),

            // Health summary section
            _buildHealthSummary(colors),

            // Collar tag section
            _buildCollarTagSection(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Cat avatar
          Hero(
            tag: 'cat_image_${widget.cat['id']}',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: widget.cat['image_url'] != null && widget.cat['image_url'].isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(widget.cat['image_url']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.cat['image_url'] == null || widget.cat['image_url'].isEmpty
                  ? Icon(
                Icons.pets,
                size: 60,
                color: colors.primary,
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Cat name
          Text(
            widget.cat['name'] ?? 'Your Cat',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),

          // Cat details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDetailChip(
                  colors,
                  Icons.cake_rounded,
                  '${widget.cat['age'] ?? 0} ${int.parse(widget.cat['age'].toString()) == 1 ? 'year' : 'years'}'
              ),
              const SizedBox(width: 12),
              _buildDetailChip(colors, Icons.pets_rounded, widget.cat['breed'] ?? 'Unknown'),
              const SizedBox(width: 12),
              _buildDetailChip(colors,
                  widget.cat['gender'] == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                  widget.cat['gender'] ?? 'Unknown'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(ColorScheme colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? colors.surface
            : colors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  colors,
                  'Weight',
                  '${widget.cat['weight'] ?? '5.2'} kg',
                  Icons.monitor_weight_rounded,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  colors,
                  'Height',
                  '${widget.cat['height'] ?? '25'} cm',
                  Icons.height_rounded,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  colors,
                  'Length',
                  '${widget.cat['length'] ?? '45'} cm',
                  Icons.straighten_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ColorScheme colors, String label, String value, IconData icon) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                colors,
                'Edit Profile',
                Icons.edit_rounded,
                onTap: () {},
              ),
              _buildActionButton(
                colors,
                'Add Record',
                Icons.add_chart_rounded,
                onTap: () => widget.onNavigateToTab(2), // Navigate to Health tab
              ),
              _buildActionButton(
                colors,
                'View Tag',
                Icons.qr_code_scanner_rounded,
                onTap: () => widget.onNavigateToTab(1), // Navigate to Collar Tag tab
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      ColorScheme colors,
      String label,
      IconData icon, {
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? colors.surface
            : colors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              InkWell(
                onTap: () => widget.onNavigateToTab(2), // Navigate to Health
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthItem(
            colors,
            'Vaccination Status',
            'Up to date',
            Icons.verified_rounded,
            true,
          ),
          const SizedBox(height: 12),
          _buildHealthItem(
            colors,
            'Last Vet Visit',
            'March 15, 2025',
            Icons.calendar_today_rounded,
            true,
          ),
          const SizedBox(height: 12),
          _buildHealthItem(
            colors,
            'Next Checkup',
            'June 15, 2025',
            Icons.event_available_rounded,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(
      ColorScheme colors,
      String label,
      String value,
      IconData icon,
      bool isPositive,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPositive ? colors.primary.withOpacity(0.1) : colors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isPositive ? colors.primary : colors.error,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollarTagSection(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? colors.surface
            : colors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collar Tag',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              InkWell(
                onTap: () => widget.onNavigateToTab(1), // Navigate to Collar Tag
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.qr_code_rounded,
                  size: 50,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Tag Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan to access pet information',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}