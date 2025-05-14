
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportLostScreen extends StatefulWidget {
  final Map<String, dynamic> cat;
  final Future<void> Function()? onRefresh;

  const ReportLostScreen({
    super.key,
    required this.cat,
    this.onRefresh,
  });

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastSeenController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Initialize with widget.cat data to prevent flicker
  late bool _isReportingLost;

  @override
  void initState() {
    super.initState();
    // Initialize directly from widget data to prevent flicker
    _isReportingLost = widget.cat['status'] ?? false;
    if (widget.cat['last_seen_location'] != null) {
      _lastSeenController.text = widget.cat['last_seen_location'];
    }
  }

  Future<void> _updateLostStatus() async {
    if (_isReportingLost && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        'status': _isReportingLost,
        'last_seen_location': _isReportingLost ? _lastSeenController.text : null,
        'reported_lost_at': _isReportingLost ? DateTime.now().toIso8601String() : null,
      };

      await _supabase
          .from('cats')
          .update(updateData)
          .eq('id', widget.cat['id']);

      // Call onRefresh to reload cat data after update
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isReportingLost
                ? '${widget.cat['name']} marked as lost'
                : '${widget.cat['name']} is no longer marked as lost'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error updating lost status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show confirmation dialog when marking as found
  Future<void> _showConfirmationDialog() async {
    // Only show dialog when trying to mark as found (turning off lost status)
    if (_isReportingLost) {
      final bool? wasFound = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm ${widget.cat['name']} Was Found'),
            content: Text('Was ${widget.cat['name']} found and returned safely?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );

      if (wasFound == true) {
        // User confirmed the cat was found, proceed with updating status
        setState(() {
          _isReportingLost = false;
        });
        await _updateLostStatus();
      } else {
        // User canceled or declined, keep status as lost
        setState(() {
          _isReportingLost = true;
        });
      }
    } else {
      // When marking as lost, no need for confirmation
      setState(() {
        _isReportingLost = true;
      });
    }
  }

  @override
  void dispose() {
    _lastSeenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header section
              _buildHeader(colors),

              const SizedBox(height: 20),

              // Status toggle card - enhanced with dashboard-like styling
              _buildStatusToggleCard(colors),

              const SizedBox(height: 20),

              // Form fields that appear when reporting lost
              if (_isReportingLost)
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: _buildLostDetailsForm(colors),
                  ),
                ),

              // Information when not reporting lost
              if (!_isReportingLost)
                Expanded(
                  child: _buildNotLostContent(colors),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isReportingLost
            ? colors.primary.withOpacity(0.15)
            : colors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'cat_lost_${widget.cat['id']}',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isReportingLost ? colors.primary : colors.primary,
                  width: 2,
                ),
                image: widget.cat['image_url'] != null && widget.cat['image_url'].isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(widget.cat['image_url']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.cat['image_url'] == null || widget.cat['image_url'].isEmpty
                  ? Icon(
                _isReportingLost ? Icons.error_outline : Icons.pets,
                size: 30,
                color: _isReportingLost ? colors.primary : colors.primary,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cat['name'],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _isReportingLost ? colors.primary : colors.primary,
                  ),
                ),
                Text(
                  _isReportingLost
                      ? 'Currently marked as lost'
                      : 'Currently not marked as lost',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isReportingLost
                        ? colors.primary.withOpacity(0.8)
                        : colors.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _isReportingLost
                  ? colors.primary.withOpacity(0.2)
                  : colors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              _isReportingLost ? Icons.report_problem : Icons.check_circle,
              color: _isReportingLost ? colors.primary : Colors.green,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggleCard(ColorScheme colors) {
    return Card(
      elevation: 2,
      shadowColor: colors.shadow.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isReportingLost ? colors.primary : colors.primary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _isReportingLost
                            ? colors.primary.withOpacity(0.2)
                            : colors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _isReportingLost ? Icons.error_outline : Icons.pets,
                        color: _isReportingLost ? colors.primary : colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isReportingLost ? 'Mark as Found' : 'Report as Lost',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isReportingLost,
                  activeColor: colors.primary,
                  activeTrackColor: colors.primary.withOpacity(0.4),
                  inactiveThumbColor: colors.primary,
                  inactiveTrackColor: colors.primary.withOpacity(0.4),
                  onChanged: (value) {
                    // Don't directly set the state - check if confirmation needed
                    if (_isReportingLost != value) {
                      if (value == false) {
                        // Trying to mark as found, show confirmation
                        _showConfirmationDialog();
                      } else {
                        // Marking as lost - no confirmation needed
                        setState(() {
                          _isReportingLost = value;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isReportingLost
                  ? 'Your cat is marked as lost. Anyone who scans the collar tag will see this information and can help return ${widget.cat['name']}.'
                  : 'If ${widget.cat['name']} is lost, toggle this switch to update the collar tag with emergency information.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collar tag information updates immediately when status changes',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostDetailsForm(ColorScheme colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.place,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Lost Pet Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time since reporting
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time since reporting',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primary,
                                ),
                              ),
                              Text(
                                widget.cat['reported_lost_at'] != null
                                    ? _formatTimeSince(widget.cat['reported_lost_at'])
                                    : 'Just now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Last seen location
                  TextFormField(
                    controller: _lastSeenController,
                    decoration: InputDecoration(
                      labelText: 'Last Seen Location',
                      hintText: 'Where was your cat last seen?',
                      hintStyle: TextStyle(
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the last seen location';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button with enhanced styling
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateLostStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Update Lost Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLostContent(ColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 48,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.cat['name']} is not reported as lost',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Toggle the switch above if you need to report your cat as lost.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your cat\'s collar tag shows normal status',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeSince(String dateTimeString) {
    try {
      final reportedAt = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(reportedAt);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}