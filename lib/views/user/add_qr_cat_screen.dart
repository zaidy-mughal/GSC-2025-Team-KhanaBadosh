import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class AddQrCatScreen extends StatefulWidget {
  const AddQrCatScreen({super.key});

  @override
  State<AddQrCatScreen> createState() => _AddQrCatScreenState();
}

class _AddQrCatScreenState extends State<AddQrCatScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Use a nullable controller - we'll initialize it in initState
  MobileScannerController? _scannerController;

  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // Delay creation to ensure Flutter engine is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the controller
      _initializeScannerController();
    });
  }

  void _initializeScannerController() {
    // Create controller with explicit parameters
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Safely dispose of the controller
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrData) async {
    // Prevent multiple processing attempts
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Parse QR code data - add more flexible parsing to handle different formats
      Map<String, dynamic> qrJson;

      try {
        // First try standard JSON parsing
        qrJson = jsonDecode(qrData);
      } catch (jsonError) {
        // If standard JSON parsing fails, try to parse the format manually
        try {
          // Handle format like {cat_id: 2, to_user_id: uuid}
          qrData = qrData.trim();
          if (qrData.startsWith('{') && qrData.endsWith('}')) {
            // Remove the braces
            qrData = qrData.substring(1, qrData.length - 1);

            // Split by comma and process each part
            final parts = qrData.split(',').map((part) => part.trim());
            qrJson = {};

            for (final part in parts) {
              final keyValue = part.split(':').map((item) => item.trim()).toList();
              if (keyValue.length == 2) {
                final key = keyValue[0];
                final value = keyValue[1];

                // Try to convert numeric values to int
                if (key == 'cat_id') {
                  qrJson[key] = int.tryParse(value) ?? value;
                } else {
                  qrJson[key] = value;
                }
              }
            }
          } else {
            throw Exception('Invalid QR code format');
          }
        } catch (e) {
          throw Exception('Could not parse QR code data: $qrData');
        }
      }

      // Print debugging info
      print('Parsed QR JSON: $qrJson');

      // Validate QR data format
      if (!qrJson.containsKey('cat_id') || !qrJson.containsKey('to_user_id')) {
        setState(() {
          _errorMessage = 'Invalid QR code format. Missing required fields.';
          _isProcessing = false;
        });
        return;
      }

      final int catId = qrJson['cat_id'] is int
          ? qrJson['cat_id']
          : int.tryParse(qrJson['cat_id'].toString()) ?? -1;

      final String toUserId = qrJson['to_user_id'].toString();

      // Print the extracted values for debugging
      print('Cat ID: $catId');
      print('To User ID: $toUserId');

      if (catId == -1) {
        setState(() {
          _errorMessage = 'Invalid cat ID format in QR code.';
          _isProcessing = false;
        });
        return;
      }

      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'You must be logged in to transfer a cat.';
          _isProcessing = false;
        });
        return;
      }

      print('Current User ID: ${currentUser.id}');

      // Verify the target user ID matches the current user
      if (toUserId != currentUser.id) {
        setState(() {
          _errorMessage = 'This cat is meant to be transferred to another user.';
          _isProcessing = false;
        });
        return;
      }

      // Check if cat exists
      try {
        final catResponse = await _supabase
            .from('cats')
            .select()
            .eq('id', catId)
            .single();

        print('Cat found: $catResponse');

        // Update cat's user_id to current user
        final updateResponse = await _supabase
            .from('cats')
            .update({'user_id': currentUser.id})
            .eq('id', catId)
            .select(); // Add .select() to see the response

        print('Update response: $updateResponse');

        setState(() {
          _successMessage = 'Cat has been successfully added to your profile!';
          _isProcessing = false;
        });

        // Return to previous screen after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to trigger cat list refresh
          }
        });
      } catch (e) {
        print('Error querying/updating cat: $e');
        setState(() {
          _errorMessage = 'Error: Unable to find or update the cat in the database. ${e.toString()}';
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error processing QR: $e');
      setState(() {
        _errorMessage = 'Error processing QR code: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Cat QR Code'),
        elevation: 0,
        actions: [
          // Only show torch toggle, no camera switcher
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
                _scannerController?.toggleTorch();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.primary.withOpacity(0.1),
            child: Text(
              'Position the QR code within the frame to transfer the cat to your profile.',
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Scanner
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR Scanner
                if (_scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        final qrData = barcodes.first.rawValue!;
                        // Stop scanning after detecting a code
                        _scannerController?.stop();
                        _processQrCode(qrData);
                      }
                    },
                    // Error builder to handle permission issues
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: colors.error, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Camera Error: ${error.errorCode}',
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _initializeScannerController,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                // Scanning overlay
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 250,
                  width: 250,
                  child: Center(
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.primary,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(),
                    ),
                  ),
                ),

                // Loading indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: colors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Processing QR code...',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Error message
                if (_errorMessage != null && !_isProcessing)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colors.onError,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                              _initializeScannerController();
                              _scannerController?.start();
                            },
                            child: Text(
                              'Try Again',
                              style: TextStyle(
                                color: colors.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Success message
                if (_successMessage != null && !_isProcessing)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Redirecting to your cats...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
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