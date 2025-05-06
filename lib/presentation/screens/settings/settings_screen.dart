import 'package:flutter/material.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isOfflineMode = false;
  bool _isDataSaving = false;
  bool _isAutomaticSync = true;
  bool _isSyncing = false;
  int _unsyncedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkUnsyncedScans();
  }
  
  Future<void> _loadSettings() async {
    // TODO: Load settings from SharedPreferences
    // For now, we'll use default values
  }
  
  Future<void> _checkUnsyncedScans() async {
    // TODO: Check for unsynced scans
    // For demonstration purposes, setting a dummy value
    setState(() {
      _unsyncedCount = 5;
    });
  }
  
  Future<void> _syncAllData() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      // TODO: Implement actual sync functionality
      // This is a placeholder to simulate syncing
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _unsyncedCount = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('SettingsScreen', 'Error syncing data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDevInfoSection(),
          _buildSyncSection(),
          _buildPreferencesSection(),
          _buildDevToolsSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }
  
  Widget _buildDevInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Development Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
                child: const Icon(
                  Icons.developer_mode,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'developer@example.com',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test Establishment',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Synchronization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _unsyncedCount > 0
                          ? '$_unsyncedCount scan(s) pending sync'
                          : 'All data is synced',
                      style: TextStyle(
                        color: _unsyncedCount > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last synced: ${_formatLastSyncTime()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _unsyncedCount > 0 && !_isSyncing
                    ? _syncAllData
                    : null,
                child: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Sync Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SwitchListTile(
            title: const Text('Offline Mode'),
            subtitle: const Text('Work without internet connection'),
            value: _isOfflineMode,
            onChanged: (value) {
              setState(() {
                _isOfflineMode = value;
              });
              // TODO: Save the setting
            },
          ),
          SwitchListTile(
            title: const Text('Data Saving Mode'),
            subtitle: const Text('Reduce data usage'),
            value: _isDataSaving,
            onChanged: (value) {
              setState(() {
                _isDataSaving = value;
              });
              // TODO: Save the setting
            },
          ),
          SwitchListTile(
            title: const Text('Automatic Sync'),
            subtitle: const Text('Sync data automatically when online'),
            value: _isAutomaticSync,
            onChanged: (value) {
              setState(() {
                _isAutomaticSync = value;
              });
              // TODO: Save the setting
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Clear Scan History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearHistoryConfirmation();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDevToolsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Development Tools',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.amber[50],
            child: ListTile(
              leading: Icon(
                Icons.qr_code_2,
                color: Colors.amber[700],
              ),
              title: const Text('QR Code Generator'),
              subtitle: const Text('Create test QR codes for development'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/qr_generator');
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.blue[50],
            child: ListTile(
              leading: Icon(
                Icons.cloud_upload,
                color: Colors.blue[700],
              ),
              title: const Text('Mock Server Response'),
              subtitle: const Text('Test server responses without API'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature coming soon!'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Development)'),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to terms of service screen
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showClearHistoryConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Scan History'),
        content: const Text(
          'Are you sure you want to clear your scan history? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // TODO: Implement clear scan history functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan history cleared'),
        ),
      );
    }
  }
  
  String _formatLastSyncTime() {
    // TODO: Get actual last sync time
    return 'Today, 10:30 AM';
  }
}