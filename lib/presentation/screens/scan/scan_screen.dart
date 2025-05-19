import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
import 'package:pwd_verification_app/di/service_locator.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key}); // Use super.key

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _hasFlash = false;
  bool _isProcessing = false;
  // double _zoomLevel = 0.0; // Zoom level not currently used, can be removed if not planned
  String? _errorMessage;

  // Assuming ScanRepository is correctly registered and provided by getIt
  final ScanRepository _scanRepository = getIt<ScanRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_scannerController.isStarting) return; // Guard against disposed controller

    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  Future<void> _initializeScanner() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        // torchEnabled: false, // Default is false
      );

      // Wait for the controller to be initialized to check torch state
      // This might need a delay or a listener on a different controller state if available
      // For now, relying on the torchState listener.
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to allow init

      if (mounted) { // Check if mounted before adding listener or setting state
        _scannerController.torchState.addListener(() {
          if (mounted) { // Check mounted again inside listener
            setState(() {
              _hasFlash = _scannerController.torchState.value == TorchState.on ||
                          _scannerController.torchState.value == TorchState.off;
              // More robust check: see if controller.info.hasTorch
            });
          }
        });
        // Check initial flash capability
        // final bool hasTorch = await _scannerController.hasTorch();
        // if (mounted) setState(() => _hasFlash = hasTorch);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
      AppLogger.error('ScanScreen', 'Camera initialization error: $e');
    }
  }

  Future<void> _onQRCodeDetected(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing || !mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrData = barcodes.first.rawValue!;
      AppLogger.info('ScanScreen', 'QR Code Detected: $qrData');

      setState(() { _isProcessing = true; });
      await _scannerController.stop(); // Stop scanning
      await _verifyQRCode(qrData);
    }
  }

  Future<void> _verifyQRCode(String qrData) async {
    try {
      // _isScanning is already set to false effectively by _isProcessing
      // setState(() { _isScanning = false; }); // Not strictly needed if _isProcessing is true

      final scanResult = await _scanRepository.verifyQRCode(qrData);

      if (mounted) {
        if (scanResult != null) {
          Navigator.pushNamed(
            context,
            '/verification_result',
            arguments: scanResult,
          ).then((_) => _resetScanner()); // Reset scanner after returning from result screen
        } else {
          _showError('Failed to verify QR code. The code might be invalid or unreadable.');
          _resetScanner();
        }
      }
    } catch (e) {
      AppLogger.error('ScanScreen', 'Error verifying QR code: $e');
      if (mounted) {
        _showError('An error occurred during verification: ${e.toString().replaceFirst("Exception: ", "")}');
        _resetScanner();
      }
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isScanning = true;
        _isProcessing = false;
      });
      // Ensure controller is started only if it's not already disposed or being started
      if (_scannerController.isStarting) {
         _scannerController.start();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error, // Use theme color
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there's a persistent camera error, show the error screen
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    // If scanner controller is not initialized yet, show a loader
    // This depends on how _initializeScanner sets up _scannerController
    // A more robust way would be to have a `_isControllerInitialized` flag
    // For now, let's assume if _errorMessage is null, controller should be ready or getting ready.

    return Scaffold(
      // No AppBar needed at the Scaffold level if building custom controls
      body: Stack(
        alignment: Alignment.center, // Center scan overlay and other elements
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQRCodeDetected,
            // Consider adding fit: BoxFit.cover if the preview doesn't fill the screen
            // fit: BoxFit.cover,
          ),

          // Scan overlay (centered by Stack's alignment)
          _buildScanOverlay(),

          // Camera controls (positioned using Align or Positioned within SafeArea)
          _buildCameraControls(),

          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),

          // Instructions (positioned at the bottom)
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      // It's good practice to have an AppBar even on error screens for consistency
      appBar: AppBar(title: const Text('Camera Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon( Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 64 ),
              const SizedBox(height: 16),
              Text( 'Camera Initialization Failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) ),
              const SizedBox(height: 8),
              Text( _errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error) ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () {
                  setState(() { _errorMessage = null; });
                  _initializeScanner(); // Re-attempt initialization
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    final Size size = MediaQuery.of(context).size;
    // Make scan area slightly smaller and ensure it's not too large on big screens
    final double scanAreaSize = (size.width * 0.65).clamp(200.0, 300.0);

    return Container(
      width: scanAreaSize,
      height: scanAreaSize,
      decoration: BoxDecoration(
        // Removed the white border, corners are enough indication
        // border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
        // borderRadius: BorderRadius.circular(12), // Optional: if you want rounded main box
      ),
      child: Stack( // For corner elements
        clipBehavior: Clip.none, // Allow corners to extend slightly
        children: [
          // Custom corners
          _buildCorner(top: 0, left: 0),
          _buildCorner(top: 0, right: 0, isTopRight: true),
          _buildCorner(bottom: 0, left: 0, isBottomLeft: true),
          _buildCorner(bottom: 0, right: 0, isBottomRight: true),

          // Scan animation (optional)
          // if (_isScanning && !_isProcessing) _buildScanAnimation(scanAreaSize),
        ],
      ),
    );
  }

  // Helper for building corners
  Widget _buildCorner({double? top, double? left, double? bottom, double? right, bool isTopRight = false, bool isBottomLeft = false, bool isBottomRight = false}) {
    const double cornerLength = 20.0;
    const double cornerThickness = 4.0;
    final Color cornerColor = Theme.of(context).primaryColor;

    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: SizedBox(
        width: cornerLength,
        height: cornerLength,
        child: CustomPaint(
          painter: _CornerPainter(
            color: cornerColor,
            strokeWidth: cornerThickness,
            isTopRight: isTopRight,
            isBottomLeft: isBottomLeft,
            isBottomRight: isBottomRight,
          ),
        ),
      ),
    );
  }


  // Scan animation (can be kept or removed based on preference)
  Widget _buildScanAnimation(double size) {
    // This is a simple animation, consider using AnimationController for more complex effects
    return Positioned(
      // This example doesn't animate, it's just a static line
      // For animation, you'd use an AnimationController and AnimatedBuilder/AnimatedWidget
      top: size / 2, // Example static position
      left: 4, right: 4, height: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Positioned.fill( // Use Positioned.fill to make SafeArea take full space
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between top and bottom controls
          children: [
            // Top bar (without back button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted padding
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center title
                children: [
                  // --- REMOVED BACK BUTTON ---
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back, color: Colors.white),
                  //   onPressed: () => Navigator.pop(context), // This was causing the issue
                  // ),
                  // const Spacer(), // If title is centered, spacer might not be needed like this

                  Expanded( // Allow title to take space and be centered
                    child: Text(
                      'Scan PWD QR Code',
                      textAlign: TextAlign.center, // Center align the title
                      style: const TextStyle( color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold ),
                    ),
                  ),

                  // Flash toggle button (ensure it's aligned correctly, e.g., with a SizedBox or Spacer if title isn't expanded)
                  // Use SizedBox to maintain space if flash is not available, ensuring title stays centered
                  SizedBox(
                    width: 48, // Same width as an IconButton
                    child: _hasFlash && _scannerController.isStarting // Only show if flash exists and controller is active
                        ? IconButton(
                            tooltip: 'Toggle Flash',
                            icon: ValueListenableBuilder<TorchState>( // Use correct generic type
                              valueListenable: _scannerController.torchState,
                              builder: (context, state, child) {
                                switch (state) {
                                  case TorchState.on:
                                    return Icon(Icons.flash_on, color: Theme.of(context).colorScheme.primaryContainer);
                                  default: // Off or Unavailable
                                    return const Icon(Icons.flash_off, color: Colors.white);
                                }
                              },
                            ),
                            onPressed: () => _scannerController.toggleTorch(),
                          )
                        : null, // Render nothing or a SizedBox if no flash
                  ),
                ],
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Increased vertical padding
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out controls
                children: [
                  IconButton(
                    tooltip: 'Switch Camera',
                    icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 28),
                    onPressed: () => _scannerController.switchCamera(),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('Manual Entry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                    onPressed: _isProcessing ? null : () { // Disable if processing
                      // Navigate to manual entry screen
                      // Consider stopping camera before navigating to save resources
                      // _scannerController.stop();
                      Navigator.pushNamed(context, '/manual_entry').then((_) {
                        // Restart camera when returning if it was stopped
                        // if (mounted && _scannerController.isStarting) _scannerController.start();
                        // Or just call reset scanner
                         _resetScanner();
                      });
                    },
                  ),
                  // Placeholder for symmetry or other control if needed
                  const SizedBox(width: 48), // Match IconButton size
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.75), // Darker overlay
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text( 'Verifying QR Code...', style: TextStyle( color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500 ) ),
            // SizedBox(height: 8),
            // Text( 'Please wait...', style: TextStyle( color: Colors.white70 ) ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    // Show instructions only when actively scanning and not processing
    if (!_isScanning || _isProcessing) return const SizedBox.shrink();

    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.15, // Position above bottom controls
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Align QR code within the frame',
            style: TextStyle( color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500 ),
          ),
        ),
      ),
    );
  }
}


// Custom Painter for the scan box corners
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    required this.color,
    this.strokeWidth = 4.0,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 20.0; // Match SizedBox in _buildCorner

    if (isTopRight) { // Top-Right
      canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);
    } else if (isBottomLeft) { // Bottom-Left
      canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    } else if (isBottomRight) { // Bottom-Right
      canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
    } else { // Top-Left (default)
      canvas.drawLine(const Offset(cornerLength, 0), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}