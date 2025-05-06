import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
import 'package:pwd_verification_app/di/service_locator.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _hasFlash = false;
  bool _isProcessing = false;
  double _zoomLevel = 0.0;
  String? _errorMessage;

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
    // Handle app lifecycle changes to properly manage camera resources
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive ||
              state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  Future<void> _initializeScanner() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        torchEnabled: false,
      );

      // Listen for camera initialization
      _scannerController.torchState.addListener(() {
        setState(() {
          _hasFlash = _scannerController.torchState.value != null;
        });
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
      AppLogger.error('ScanScreen', 'Camera initialization error: $e');
    }
  }

  Future<void> _onQRCodeDetected(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });
        
        await _scannerController.stop();
        await _verifyQRCode(barcode.rawValue!);
        break;
      }
    }
  }
  
  Future<void> _verifyQRCode(String qrData) async {
    try {
      // Show loading indicator
      setState(() {
        _isScanning = false;
      });
      
      // Verify QR code
      final scanResult = await _scanRepository.verifyQRCode(qrData);
      
      if (scanResult != null) {
        // Navigate to result screen
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/verification_result',
            arguments: scanResult,
          ).then((_) => _resetScanner());
        }
      } else {
        _showError('Failed to verify QR code. Please try again.');
        _resetScanner();
      }
    } catch (e) {
      _showError('An error occurred: $e');
      _resetScanner();
    }
  }
  
  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isScanning = true;
        _isProcessing = false;
      });
      _scannerController.start();
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQRCodeDetected,
          ),
          
          // Scan overlay
          _buildScanOverlay(),
          
          // Camera controls
          _buildCameraControls(),
          
          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),
          
          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }
  
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initializeScanner();
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
    final double scanAreaSize = size.width * 0.7;
    
    return Center(
      child: Container(
        width: scanAreaSize,
        height: scanAreaSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Top-left corner
            Positioned(
              top: -5,
              left: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                    left: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            // Top-right corner
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                    right: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            // Bottom-left corner
            Positioned(
              bottom: -5,
              left: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                    left: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            // Bottom-right corner
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                    right: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            // Scan animation
            if (_isScanning) _buildScanAnimation(scanAreaSize),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScanAnimation(double size) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      top: _isScanning ? size - 4 : 4,
      left: 4,
      right: 4,
      height: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Theme.of(context).primaryColor,
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCameraControls() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Scan PWD QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasFlash)
                  IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: _scannerController.torchState,
                      builder: (context, state, child) {
                        switch (state) {
                          case TorchState.on:
                            return const Icon(Icons.flash_on, color: Colors.yellow);
                          case TorchState.off:
                            return const Icon(Icons.flash_off, color: Colors.white);
                          default:
                            return const Icon(Icons.flash_off, color: Colors.white);
                        }
                      },
                    ),
                    onPressed: () => _scannerController.toggleTorch(),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          const Spacer(),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => _scannerController.switchCamera(),
                ),
                // Manual entry button
                ElevatedButton.icon(
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Manual Entry'),
                  onPressed: () {
                    // Navigate to manual entry screen
                    Navigator.pushNamed(context, '/manual_entry');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: _resetScanner,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Verifying QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait...',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'Place QR code inside the frame',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}