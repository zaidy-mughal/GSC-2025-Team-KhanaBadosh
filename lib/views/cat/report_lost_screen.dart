import 'package:flutter/material.dart';

class ReportLostScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const ReportLostScreen({
    Key? key,
    required this.cat,
  }) : super(key: key);

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  bool _isReportingLost = false;
  final _formKey = GlobalKey<FormState>();
  final _lastSeenController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _lastSeenController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
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
                  color: _isReportingLost
                      ? colors.errorContainer
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isReportingLost ? Icons.error_outline : Icons.pets,
                      color: _isReportingLost ? colors.error : colors.onSurfaceVariant,
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
                              color: _isReportingLost ? colors.onErrorContainer : colors.onSurfaceVariant,
                            ),
                          ),
                          if (_isReportingLost)
                            Text(
                              'Your contact details are visible to anyone who scans the collar tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onErrorContainer.withOpacity(0.8),
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
                  color: colors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isReportingLost
                        ? colors.error
                        : colors.outlineVariant,
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
                          activeColor: colors.error,
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
                          ? 'Your cat is marked as lost. Anyone who scans the collar tag will see your contact details and information to help return ${widget.cat['name']}.'
                          : 'If ${widget.cat['name']} is lost, toggle this switch to update the collar tag with emergency contact information.',
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the last seen location';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Any unique traits or details that would help identify your cat',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.description_outlined),
                            ),
                            maxLines: 3,
                          ),

                          const SizedBox(height: 16),

                          // Contact information
                          TextFormField(
                            controller: _contactController,
                            decoration: InputDecoration(
                              labelText: 'Contact Information',
                              hintText: 'Your phone number and/or email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.contact_phone_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please provide contact information';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Process form data and update lost status
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lost status updated'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
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
                        'Toggle the switch above to update the collar tag with your emergency contact information.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
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