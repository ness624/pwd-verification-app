import 'package:flutter/material.dart';
import 'package:pwd_verification_app/presentation/screens/scan/scan_screen.dart';
import 'package:pwd_verification_app/presentation/screens/scan/scan_history_screen.dart';
import 'package:pwd_verification_app/presentation/screens/settings/settings_screen.dart';
// Import the AnalyticsScreen
import 'package:pwd_verification_app/presentation/screens/analytics/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  // Use const constructor and super parameters
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start with the first screen (Scan)

  // Add AnalyticsScreen to the list of screens
  final List<Widget> _screens = [
    const ScanScreen(),
    const ScanHistoryScreen(),
    const AnalyticsScreen(), // Added Analytics Screen
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dynamic AppBar title based on the selected screen
      appBar: AppBar(
        title: _buildTitle(),
        actions: [
          _buildConnectionStatus(), // Keep connection status indicator
        ],
      ),
      // Display the screen corresponding to the current index
      body: IndexedStack( // Use IndexedStack to keep state of inactive screens
        index: _currentIndex,
        children: _screens,
      ),
      // Build the bottom navigation bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Build the title based on the current index
  Widget _buildTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text('Scan QR Code');
      case 1:
        return const Text('Scan History');
      case 2:
        return const Text('Analytics'); // Added title for Analytics
      case 3:
        return const Text('Settings');
      default:
        return const Text('PWD Verification'); // Default title
    }
  }

  // Widget to display connection status (keep as is for now)
  Widget _buildConnectionStatus() {
    // TODO: Implement actual connectivity check using Connectivity Bloc/Service
    const bool isConnected = true; // Placeholder

    return Padding(
      padding: const EdgeInsets.only(right: 12.0), // Increased padding slightly
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.signal_wifi_off, // Changed icon for offline
            color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error, // Use theme colors
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error, // Use theme colors
            ),
          ),
        ],
      ),
    );
  }

  // Build the bottom navigation bar with the new Analytics item
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      // Important: Set type to fixed when having more than 3 items
      // to prevent items from disappearing or behaving unexpectedly.
      type: BottomNavigationBarType.fixed,
      // Add the Analytics item to the list
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined), // Icon for Analytics
          label: 'Analytics', // Label for Analytics
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined), // Changed icon for settings
          label: 'Settings',
        ),
      ],
      // Optional: Customize selected/unselected item colors if needed
      // selectedItemColor: Theme.of(context).colorScheme.primary,
      // unselectedItemColor: Colors.grey,
    );
  }
}