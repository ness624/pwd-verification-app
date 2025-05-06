import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:intl/intl.dart';

class VerificationResultScreen extends StatefulWidget {
  final ScanResult scanResult;
  
  const VerificationResultScreen({
    Key? key,
    required this.scanResult,
  }) : super(key: key);

  @override
  State<VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSyncingWithServer = false;
  Timer? _autoCloseTimer;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoCloseTimer();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }
  
  void _startAutoCloseTimer() {
    if (widget.scanResult.isValid) {
      // Auto-close after 20 seconds for valid results
      _autoCloseTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
  
  void _syncWithServer() async {
    if (_isSyncingWithServer) return;
    
    setState(() {
      _isSyncingWithServer = true;
    });
    
    try {
      // Simulate server sync
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced with server successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('VerificationResultScreen', 'Error syncing with server: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync with server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingWithServer = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildPWDInfoCard(),
                      const SizedBox(height: 24),
                      _buildScanDetailsCard(),
                      if (!widget.scanResult.isValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: _buildInvalidReasonCard(),
                        ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    final isValid = widget.scanResult.isValid;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isValid ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isValid ? Icons.check_circle : Icons.cancel,
                  color: isValid ? Colors.green : Colors.red,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isValid ? 'Valid PWD ID' : 'Invalid PWD ID',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isValid ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isValid 
                ? 'This PWD ID is valid and has been verified successfully'
                : 'This PWD ID could not be verified',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isValid ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPWDInfoCard() {
    final pwdInfo = widget.scanResult.pwdInfo;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPWDPhoto(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pwdInfo.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PWD ID: ${pwdInfo.pwdNumber}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Disability Type',
              value: pwdInfo.disabilityType,
            ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Expiry Date',
              value: _formatDate(pwdInfo.expiryDate),
              isHighlighted: pwdInfo.isExpired,
              highlightColor: Colors.red,
            ),
            if (pwdInfo.address != null && pwdInfo.address!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Address',
                value: pwdInfo.address!,
              ),
            if (pwdInfo.contactNumber != null && pwdInfo.contactNumber!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Contact',
                value: pwdInfo.contactNumber!,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPWDPhoto() {
    final pwdInfo = widget.scanResult.pwdInfo;
    
    if (pwdInfo.photo != null && pwdInfo.photo!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(pwdInfo.photo!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPhotoPlaceholder();
            },
          ),
        );
      } catch (e) {
        AppLogger.error('VerificationResultScreen', 'Error decoding photo: $e');
        return _buildPhotoPlaceholder();
      }
    } else {
      return _buildPhotoPlaceholder();
    }
  }
  
  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.person,
        size: 48,
        color: Colors.grey.shade500,
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
    Color highlightColor = Colors.red,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? highlightColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Scan Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(
              label: 'Scan ID:',
              value: widget.scanResult.scanId.substring(0, 8),
            ),
            _buildDetailRow(
              label: 'Scan Time:',
              value: _formatDateTime(widget.scanResult.scanTime),
            ),
            _buildDetailRow(
              label: 'Establishment:',
              value: widget.scanResult.establishmentName,
            ),
            if (widget.scanResult.establishmentLocation != null)
              _buildDetailRow(
                label: 'Location:',
                value: widget.scanResult.establishmentLocation!,
              ),
            _buildDetailRow(
              label: 'Sync Status:',
              value: widget.scanResult.isSyncedWithServer ? 'Synced' : 'Pending',
              valueColor: widget.scanResult.isSyncedWithServer ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvalidReasonCard() {
    if (widget.scanResult.invalidReason == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invalid Reason',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.scanResult.invalidReason!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.amber.shade900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Invalid PWD IDs should be reported to proper authorities if suspected of fraud.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              icon: _isSyncingWithServer 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
              label: Text(_isSyncingWithServer ? 'Syncing...' : 'Sync Now'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: !widget.scanResult.isSyncedWithServer && !_isSyncingWithServer
                ? _syncWithServer
                : null,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  String _formatDateTime(DateTime dateTime) {
    final date = DateFormat('MMM d, yyyy').format(dateTime);
    final time = DateFormat('h:mm a').format(dateTime);
    return '$date at $time';
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Valid QR Code',
              description: 'A green checkmark indicates that the PWD ID is valid.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.cancel,
              color: Colors.red,
              title: 'Invalid QR Code',
              description: 'A red X indicates that the PWD ID is invalid or expired.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.sync,
              color: Colors.blue,
              title: 'Sync Status',
              description: 'Shows whether the scan has been synced with the server.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}