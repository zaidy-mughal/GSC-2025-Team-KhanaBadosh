import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'view_qr_found_screen.dart';

class QRFoundScreen extends StatefulWidget {
  const QRFoundScreen({super.key});

  @override
  State<QRFoundScreen> createState() => _QRFoundScreenState();
}

class _QRFoundScreenState extends State<QRFoundScreen> {
  // Use a nullable controller - we'll initialize it in initState
  MobileScannerController? _scannerController;

  bool _isProcessing = false;
  String? _errorMessage;
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
          // Handle format like {id: 2, user_id: uuid, note: text}
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
                if (key == 'id') {
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

      // Validate QR data format - we only need id and user_id
      if (!qrJson.containsKey('id') || !qrJson.containsKey('user_id')) {
        setState(() {
          _errorMessage = 'Invalid QR code format. Missing required fields.';
          _isProcessing = false;
        });
        return;
      }

      final int catId = qrJson['id'] is int
          ? qrJson['id']
          : int.tryParse(qrJson['id'].toString()) ?? -1;

      final String userId = qrJson['user_id'].toString();

      // Print the extracted values for debugging
      print('Cat ID: $catId');
      print('User ID: $userId');

      if (catId == -1) {
        setState(() {
          _errorMessage = 'Invalid cat ID format in QR code.';
          _isProcessing = false;
        });
        return;
      }

      // Navigate to the view_qr_found_screen.dart passing the extracted data
      if (mounted) {
        Navigator.pop(context); // First pop the scanner screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewQRFoundScreen(
              catId: catId,
              userId: userId,
            ),
          ),
        );
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
        title: const Text('Scan Pet QR Code'),
        elevation: 0,
        actions: [
          // Only show torch toggle
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
              'Position the QR code within the frame to view pet details.',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}