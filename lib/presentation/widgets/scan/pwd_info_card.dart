// pwd_info_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pwd_verification_app/data/models/pwd_info.dart';

class PWDInfoCard extends StatelessWidget {
  final PWDInfo pwdInfo;
  
  const PWDInfoCard({
    Key? key,
    required this.pwdInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
                      const SizedBox(height: 4),
                      _buildInfoRow('PWD ID:', pwdInfo.pwdNumber),
                      _buildInfoRow(
                        'Disability:',
                        pwdInfo.disabilityType,
                      ),
                      _buildInfoRow(
                        'Expiry Date:',
                        _formatDate(pwdInfo.expiryDate),
                        isExpired: pwdInfo.isExpired,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (pwdInfo.address != null)
              _buildInfoRow('Address:', pwdInfo.address!),
            if (pwdInfo.contactNumber != null)
              _buildInfoRow('Contact:', pwdInfo.contactNumber!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPWDPhoto() {
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
          ),
        );
      } catch (e) {
        // If there's an error decoding the image, fallback to placeholder
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
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isExpired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isExpired ? Colors.red : Colors.black87,
                fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}