// File: lib/presentation/screens/tools/qr_generator_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pwd_verification_app/data/models/pwd_info.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:intl/intl.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _pwdNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  String _disabilityType = 'Visual';
  String? _generatedQRData;
  
  final List<String> _disabilityTypes = [
    'Visual',
    'Hearing',
    'Physical',
    'Intellectual',
    'Psychosocial',
    'Multiple',
    'Learning',
    'Chronic Illness',
    'Speech',
    'Other'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _pwdNumberController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    if (_formKey.currentState?.validate() ?? false) {
      // Create PWD info
      final pwdInfo = PWDInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID
        fullName: _fullNameController.text.trim(),
        pwdNumber: _pwdNumberController.text.trim(),
        expiryDate: _expiryDate,
        disabilityType: _disabilityType,
        address: _addressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
      );

      // Convert to JSON
      final jsonString = jsonEncode(pwdInfo.toJson());

      // Encrypt the data
      final encryptedData = _encryptData(jsonString);

      setState(() {
        _generatedQRData = encryptedData;
      });
    }
  }

  String _encryptData(String data) {
    try {
      // Generate a key (in a real app, you would use a stored key)
      final key = encrypt.Key.fromSecureRandom(32);
      
      // Create an encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      // Generate IV
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Encrypt
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Combine IV and encrypted data
      final combined = '${iv.base64}:${encrypted.base64}';
      
      // Base64 encode the entire result
      final result = base64Encode(utf8.encode(combined));
      
      // Log the key and IV for debugging (in a real app, you would store these securely)
      AppLogger.info('QrGenerator', 'Generated QR Code');
      AppLogger.debug('QrGenerator', 'Encryption Key: ${key.base64}');
      AppLogger.debug('QrGenerator', 'IV: ${iv.base64}');
      
      return result;
    } catch (e) {
      AppLogger.error('QrGenerator', 'Encryption error: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generate Test QR Code',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a QR code with sample PWD information for testing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 32),
            if (_generatedQRData != null) _buildQRCodeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter PWD full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pwdNumberController,
            decoration: const InputDecoration(
              labelText: 'PWD ID Number',
              hintText: 'Enter PWD ID number',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a PWD ID number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Disability Type',
              border: OutlineInputBorder(),
            ),
            value: _disabilityType,
            items: _disabilityTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _disabilityType = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null && picked != _expiryDate) {
                setState(() {
                  _expiryDate = picked;
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_expiryDate),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address (Optional)',
              hintText: 'Enter address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactNumberController,
            decoration: const InputDecoration(
              labelText: 'Contact Number (Optional)',
              hintText: 'Enter contact number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateQRCode,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Generate QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Generated QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: _generatedQRData!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${_fullNameController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('PWD ID: ${_pwdNumberController.text}'),
            Text('Expires: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}'),
            const SizedBox(height: 16),
            const Text(
              'Scan with the app to verify',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      _fullNameController.clear();
                      _pwdNumberController.clear();
                      _addressController.clear();
                      _contactNumberController.clear();
                      _disabilityType = 'Visual';
                      _expiryDate = DateTime.now().add(const Duration(days: 365));
                      _generatedQRData = null;
                    });
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save QR'),
                  onPressed: () {
                    // TODO: Implement QR code saving functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR Code saved to gallery!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}