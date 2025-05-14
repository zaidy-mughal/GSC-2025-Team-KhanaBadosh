import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportLostScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const ReportLostScreen({
    super.key,
    required this.cat,
  });

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  bool _isReportingLost = false;
  final _formKey = GlobalKey<FormState>();
  final _lastSeenController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCatStatus();
  }

  Future<void> _loadCatStatus() async {
    try {
      final response = await _supabase
          .from('cats')
          .select('status, last_seen_location')
          .eq('id', widget.cat['id'])
          .single();

      setState(() {
        _isReportingLost = response['status'] ?? false;
        if (response['last_seen_location'] != null) {
          _lastSeenController.text = response['last_seen_location'];
        }
      });
    } catch (e) {
      // Handle error silently or show a small notification
      debugPrint('Error loading cat status: $e');
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
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isReportingLost ? Icons.error_outline : Icons.pets,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isReportingLost
                                ? '${widget.cat['name']} is marked as lost'
                                : '${widget.cat['name']} is not reported as lost',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          if (_isReportingLost)
                            Text(
                              'Anyone who scans the collar tag will see this information',
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

              const SizedBox(height: 24),

              // Report lost toggle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isReportingLost ? 'Cancel Lost Status' : 'Report ${widget.cat['name']} as Lost',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Switch(
                          value: _isReportingLost,
                          activeColor: colors.primary,
                          onChanged: (value) {
                            setState(() {
                              _isReportingLost = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _isReportingLost
                          ? 'Your cat is marked as lost. Anyone who scans the collar tag will see this information to help return ${widget.cat['name']}.'
                          : 'If ${widget.cat['name']} is lost, toggle this switch to update the collar tag with emergency information.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form fields that appear when reporting lost
              if (_isReportingLost)
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lost Pet Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: colors.surface.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the last seen location';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateLostStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: colors.primary.withOpacity(0.6),
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
                    ),
                  ),
                ),

              // Information when not reporting lost
              if (!_isReportingLost)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 64,
                        color: colors.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Need to report ${widget.cat['name']} as lost?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toggle the switch above to update the collar tag with lost information.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Add button to update status even when not reporting lost
                      if (!_isReportingLost)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateLostStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                              'Confirm Status',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}