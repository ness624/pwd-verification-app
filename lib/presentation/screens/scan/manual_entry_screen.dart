import 'package:flutter/material.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
import 'package:pwd_verification_app/di/service_locator.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pwdIdController = TextEditingController();
  final ScanRepository _scanRepository = getIt<ScanRepository>();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // PWD ID format regex: PWD-YYYY-R-XXXXX
  // YYYY = Year (2000-2099)
  // R = Region (1-17)
  // XXXXX = 5-digit series number
  final RegExp _pwdIdPattern = RegExp(r'^PWD-20\d{2}-([1-9]|1[0-7])-\d{5}$');
  
  @override
  void dispose() {
    _pwdIdController.dispose();
    super.dispose();
  }
  
  void _verifyPwdId() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        // Get the ID in the format the system expects
        final pwdId = _pwdIdController.text.trim();
        
        // Convert PWD ID to a QR code data format
        // In real app, this would call a special API endpoint
        // For now, we'll simulate with the manual entry tag
        final qrData = "MANUAL:$pwdId";
        
        // Process the verification
        final scanResult = await _scanRepository.verifyQRCode(qrData);
        
        setState(() {
          _isLoading = false;
        });
        
        if (scanResult != null) {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/verification_result',
              arguments: scanResult,
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to verify PWD ID. Please check the ID and try again.';
          });
        }
      } catch (e) {
        AppLogger.error('ManualEntryScreen', 'Error verifying PWD ID: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual PWD ID Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Info card about manual entry
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manual Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this form when the QR code is damaged or cannot be scanned. '
                      'Enter the PWD ID number exactly as it appears on the ID card.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Format: PWD-YYYY-R-XXXXX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Example: PWD-2022-4-12345',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Entry form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _pwdIdController,
                    decoration: const InputDecoration(
                      labelText: 'PWD ID Number',
                      hintText: 'PWD-YYYY-R-XXXXX',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    maxLength: 15,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the PWD ID';
                      }
                      
                      if (!_pwdIdPattern.hasMatch(value)) {
                        return 'Invalid format. Use PWD-YYYY-R-XXXXX';
                      }
                      
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPwdId,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Verifying...'),
                            ],
                          )
                        : const Text('Verify PWD ID'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code Instead'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}