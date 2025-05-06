import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/core/services/connectivity_service.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_event.dart';
import 'package:pwd_verification_app/presentation/bloc/connectivity/connectivity_state.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  final Widget? onlineChild;
  final Widget? offlineChild;
  final bool showSnackbar;
  
  const ConnectivityStatusWidget({
    Key? key,
    this.onlineChild,
    this.offlineChild,
    this.showSnackbar = true,
  }) : super(key: key);

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  ConnectionStatus? _previousStatus;
  
  @override
  void initState() {
    super.initState();
    // Start monitoring connectivity
    context.read<ConnectivityBloc>().add(ConnectivityStartMonitoring());
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityStatus) {
          // Show snackbar only when connectivity status changes
          if (_previousStatus != null && 
              _previousStatus != state.status && 
              widget.showSnackbar) {
            _showConnectivitySnackbar(context, state);
          }
          
          _previousStatus = state.status;
        }
      },
      builder: (context, state) {
        if (state is ConnectivityStatus) {
          if (state.isConnected) {
            return widget.onlineChild ?? _buildDefaultOnlineWidget(state);
          } else {
            return widget.offlineChild ?? _buildDefaultOfflineWidget();
          }
        }
        
        // Initial or unknown state, show online by default
        return widget.onlineChild ?? _buildDefaultOnlineWidget(null);
      },
    );
  }
  
  Widget _buildDefaultOnlineWidget(ConnectivityStatus? state) {
    if (state == null) {
      return const SizedBox.shrink();
    }
    
    IconData connectivityIcon;
    Color iconColor;
    
    if (state.isWifi) {
      connectivityIcon = Icons.wifi;
      iconColor = Colors.green;
    } else if (state.isMobile) {
      connectivityIcon = Icons.signal_cellular_4_bar;
      iconColor = Colors.green;
    } else {
      connectivityIcon = Icons.signal_cellular_connected_no_internet_4_bar;
      iconColor = Colors.orange;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          connectivityIcon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          state.isWifi ? 'Online (WiFi)' : 'Online (Mobile)',
          style: TextStyle(
            fontSize: 12,
            color: iconColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultOfflineWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off,
          size: 16,
          color: Colors.red,
        ),
        const SizedBox(width: 4),
        const Text(
          'Offline',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
  
  void _showConnectivitySnackbar(BuildContext context, ConnectivityStatus state) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            state.isConnected ? Icons.wifi : Icons.cloud_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(state.message),
        ],
      ),
      backgroundColor: state.isConnected ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      action: state.isConnected 
          ? null
          : SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // Open device network settings
                // TODO: Implement opening network settings
              },
            ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// A compact version of the connectivity widget that can be used in app bars
class CompactConnectivityIndicator extends StatelessWidget {
  const CompactConnectivityIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityStatus) {
          Color indicatorColor;
          IconData iconData;
          String toolTip;
          
          switch (state.status) {
            case ConnectionStatus.wifi:
              indicatorColor = Colors.green;
              iconData = Icons.wifi;
              toolTip = 'Connected to WiFi';
              break;
            case ConnectionStatus.mobile:
              indicatorColor = Colors.green;
              iconData = Icons.signal_cellular_4_bar;
              toolTip = 'Connected to Mobile Data';
              break;
            case ConnectionStatus.offline:
              indicatorColor = Colors.red;
              iconData = Icons.cloud_off;
              toolTip = 'No Internet Connection';
              break;
            case ConnectionStatus.unknown:
              indicatorColor = Colors.orange;
              iconData = Icons.help_outline;
              toolTip = 'Connection Status Unknown';
              break;
          }
          
          return Tooltip(
            message: toolTip,
            child: Icon(
              iconData,
              color: indicatorColor,
              size: 18,
            ),
          );
        }
        
        // Initial or unknown state
        return const Tooltip(
          message: 'Checking connection...',
          child: Icon(
            Icons.sync,
            color: Colors.grey,
            size: 18,
          ),
        );
      },
    );
  }
}

// A banner that appears at the top of the screen when offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityStatus && !state.isConnected) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.red,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'You are currently offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}