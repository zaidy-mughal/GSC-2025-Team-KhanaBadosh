import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HealthScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const HealthScreen({
    super.key,
    required this.cat,
  });

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with AutomaticKeepAliveClientMixin {
  // Keep this state alive when navigating
  @override
  bool get wantKeepAlive => true;

  // Mock health data (in a real app, this would come from a database)
  final List<Map<String, dynamic>> _healthRecords = [
    {
      'date': DateTime(2025, 3, 15),
      'type': 'Checkup',
      'doctor': 'Dr. Smith',
      'notes': 'Regular checkup. All vitals normal.',
      'icon': Icons.check_circle_rounded,
    },
    {
      'date': DateTime(2025, 2, 10),
      'type': 'Vaccination',
      'doctor': 'Dr. Johnson',
      'notes': 'Annual rabies and FVRCP booster shots administered.',
      'icon': Icons.medical_services_rounded,
    },
    {
      'date': DateTime(2024, 12, 5),
      'type': 'Dental Cleaning',
      'doctor': 'Dr. Wilson',
      'notes': 'Dental scaling performed. Minor tartar buildup removed.',
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'date': DateTime(2024, 10, 18),
      'type': 'Treatment',
      'doctor': 'Dr. Smith',
      'notes': 'Minor ear infection treated with antibiotics. Follow-up in 2 weeks.',
      'icon': Icons.healing_rounded,
    },
  ];

  final List<Map<String, dynamic>> _upcomingVisits = [
    {
      'date': DateTime(2025, 6, 15),
      'type': 'Checkup',
      'doctor': 'Dr. Smith',
      'notes': 'Regular checkup',
    },
    {
      'date': DateTime(2025, 8, 20),
      'type': 'Vaccination',
      'doctor': 'Dr. Johnson',
      'notes': 'Booster shots',
    },
  ];

  final List<Map<String, dynamic>> _medications = [
    {
      'name': 'Heartworm Prevention',
      'schedule': 'Monthly',
      'lastTaken': DateTime(2025, 4, 15),
      'nextDue': DateTime(2025, 5, 15),
    },
    {
      'name': 'Flea & Tick Prevention',
      'schedule': 'Monthly',
      'lastTaken': DateTime(2025, 4, 15),
      'nextDue': DateTime(2025, 5, 15),
    },
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health summary banner
            _buildHealthSummaryBanner(colors),

            // Key health metrics section
            _buildKeyHealthMetrics(colors),

            // Upcoming visits section
            _buildUpcomingVisits(colors),

            // Medications section
            _buildMedications(colors),

            // Health history section
            _buildHealthHistory(colors),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddHealthRecordDialog();
        },
      ),
    );
  }

  Widget _buildHealthSummaryBanner(ColorScheme colors) {
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
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Health Status',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Healthy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Last checked on ${DateFormat('MMMM d, yyyy').format(_healthRecords.first['date'])}',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyHealthMetrics(ColorScheme colors) {
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
            'Key Health Metrics',
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
                child: _buildMetricItem(
                  colors,
                  'Weight',
                  '${widget.cat['weight'] ?? '5.2'} kg',
                  Icons.monitor_weight_rounded,
                  '2% increase',
                  true,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  colors,
                  'Temperature',
                  '38.6°C',
                  Icons.thermostat_rounded,
                  'Normal',
                  true,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  colors,
                  'Heart Rate',
                  '140 bpm',
                  Icons.favorite_rounded,
                  'Normal',
                  true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      ColorScheme colors,
      String label,
      String value,
      IconData icon,
      String status,
      bool isPositive,
      ) {
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
            fontSize: 14,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingVisits(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'Upcoming Visits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              InkWell(
                onTap: () {},
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
                        'Add',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add,
                        size: 14,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _upcomingVisits.length,
                (index) => _buildVisitItem(colors, _upcomingVisits[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitItem(ColorScheme colors, Map<String, dynamic> visit, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: index < _upcomingVisits.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(visit['date']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(visit['date']),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit['type'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visit['doctor'],
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visit['notes'],
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.calendar_today_rounded,
            color: colors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMedications(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'Medications & Treatments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              InkWell(
                onTap: () {},
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
                        'Add',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add,
                        size: 14,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _medications.length,
                (index) => _buildMedicationItem(colors, _medications[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(ColorScheme colors, Map<String, dynamic> medication, int index) {
    final daysUntilDue = medication['nextDue'].difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;

    return Container(
      margin: EdgeInsets.only(bottom: index < _medications.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.5) : colors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.withOpacity(0.1) : colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.medication_rounded,
              color: isOverdue ? Colors.red : colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule: ${medication['schedule']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 12,
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last: ${DateFormat('MMM d').format(medication['lastTaken'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.event_rounded,
                      size: 12,
                      color: isOverdue ? Colors.red : colors.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${DateFormat('MMM d').format(medication['nextDue'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : colors.onSurface.withOpacity(0.6),
                        fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOverdue ? 'Overdue' : 'On Track',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOverdue ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthHistory(ColorScheme colors) {
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
            'Health History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _healthRecords.length,
                (index) => _buildHealthRecordItem(colors, _healthRecords[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordItem(ColorScheme colors, Map<String, dynamic> record, int index) {
    return InkWell(
      onTap: () => _showHealthRecordDetails(record),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: index < _healthRecords.length - 1 ? 16 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left timeline
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    record['icon'] ?? Icons.event_note_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                if (index < _healthRecords.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: colors.primary.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Record details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record['type'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(record['date']),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record['doctor'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record['notes'],
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHealthRecordDetails(Map<String, dynamic> record) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record['type'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(colors, 'Date', DateFormat('MMMM d, yyyy').format(record['date'])),
            _buildDetailRow(colors, 'Doctor', record['doctor']),
            _buildDetailRow(colors, 'Notes', record['notes']),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text('Edit Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ColorScheme colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            value,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHealthRecordDialog() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Health Record',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surface,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Doctor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Record'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
