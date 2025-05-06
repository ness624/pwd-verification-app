import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/di/service_locator.dart';

// Import ScanBloc, State, and Event files explicitly
import 'package:pwd_verification_app/presentation/bloc/scan/scan_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/scan/scan_state.dart'; // <-- Import State File
import 'package:pwd_verification_app/presentation/bloc/scan/scan_event.dart'; // <-- Import Event File

// Import other necessary components
import 'package:pwd_verification_app/presentation/widgets/common/app_loader.dart';
import 'package:pwd_verification_app/presentation/widgets/common/error_view.dart';
import 'package:pwd_verification_app/presentation/widgets/connectivity/connectivity_widgets.dart';
import 'package:intl/intl.dart';


class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late final ScanBloc _scanBloc;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Local state variables for filters
  String _searchQuery = '';
  bool _showOnlyValid = false;
  bool _showOnlyInvalid = false;
  bool _showOnlyUnsynced = false;
  DateTime? _selectedDate;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scanBloc = getIt<ScanBloc>();
    final currentState = _scanBloc.state;
    // Now these state types should be recognized from the import
    if (currentState is! ScanHistoryLoaded && currentState is! ScanInProgress) {
      _scanBloc.add(const LoadScanHistory()); // LoadScanHistory should be recognized
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() => _searchQuery = _searchController.text );
    }
  }

  void _resetFilters() {
     if (_searchQuery.isNotEmpty || _showOnlyValid || _showOnlyInvalid || _showOnlyUnsynced || _selectedDate != null) {
       setState(() {
         WidgetsBinding.instance.addPostFrameCallback((_) => _searchController.clear());
         _searchQuery = ''; _showOnlyValid = false; _showOnlyInvalid = false; _showOnlyUnsynced = false; _selectedDate = null;
       });
    }
    if(_isSearching) _searchFocusNode.unfocus();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
      else { _searchQuery = ''; WidgetsBinding.instance.addPostFrameCallback((_) => _searchController.clear()); _searchFocusNode.unfocus(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scanBloc,
      child: Scaffold(
        appBar: _buildAppBar(), // Only ONE call to _buildAppBar here
        body: Column( children: [ const OfflineBanner(), _buildFilterChipsArea(), Expanded(child: _buildScanHistoryContent()) ] ),
      ),
    );
  }

 // --- Only ONE definition of _buildAppBar ---
 PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
       return AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _toggleSearch),
        title: TextField(
          controller: _searchController, focusNode: _searchFocusNode,
          decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white70)),
          style: const TextStyle(color: Colors.white), cursorColor: Colors.white, autofocus: true,
        ),
        actions: [
          if (_searchQuery.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()),
        ],
      );
    }
    // Default AppBar
    return AppBar(
      title: const Text('Scan History'),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch, tooltip: 'Search'),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilterBottomSheet(context), tooltip: 'Filter'),
      ],
    );
  }

 // Filter Chips Area - keep as is
 Widget _buildFilterChipsArea() {
     final bool hasActiveFilters = _showOnlyValid || _showOnlyInvalid || _showOnlyUnsynced || _selectedDate != null;
     return AnimatedContainer(
       duration: const Duration(milliseconds: 300), height: hasActiveFilters ? 56 : 0,
       child: SingleChildScrollView(
         scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         clipBehavior: Clip.none,
         child: hasActiveFilters ? Row(children: [
             if (_showOnlyValid) _buildFilterChip('Valid Only', Colors.green, () => setState(() => _showOnlyValid = false)),
             if (_showOnlyInvalid) _buildFilterChip('Invalid Only', Colors.red, () => setState(() => _showOnlyInvalid = false)),
             if (_showOnlyUnsynced) _buildFilterChip('Unsynced Only', Colors.orange, () => setState(() => _showOnlyUnsynced = false)),
             if (_selectedDate != null) _buildFilterChip(DateFormat('MMM d, yyyy').format(_selectedDate!), Colors.blue, () => setState(() => _selectedDate = null)),
             Padding(padding: const EdgeInsets.only(left: 8.0), child: ActionChip(label: const Text('Clear All'), onPressed: _resetFilters, avatar: const Icon(Icons.clear_all, size: 16), backgroundColor: Colors.grey.shade300)),
         ]) : null,
       ),
     );
  }

  // Filter Chip builder - keep as is (with brightness fix)
  Widget _buildFilterChip(String label, Color color, VoidCallback onDeleted) {
    final Brightness brightness = ThemeData.estimateBrightnessForColor(color);
    final Color textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
    return Padding( padding: const EdgeInsets.only(right: 8.0), child: Chip( label: Text(label), backgroundColor: color.withOpacity(0.15), labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500), onDeleted: onDeleted, deleteIcon: Icon(Icons.cancel, size: 18, color: textColor.withOpacity(0.7)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4) ) );
  }

  // Scan History Content - keep as is (using 'is' checks)
  Widget _buildScanHistoryContent() {
    return BlocBuilder<ScanBloc, ScanState>( // ScanState should be recognized now
      builder: (context, state) {
        // State classes should be recognized now
        if (state is ScanInProgress) {
          return const AppLoader(message: 'Loading scan history...');
        }
        else if (state is ScanFailure) {
          return ErrorView(
            message: state.message,
            onRetry: () => _scanBloc.add(const LoadScanHistory()), // Event should be recognized
          );
        }
        else if (state is ScanHistoryLoaded) {
          final List<ScanResult> history = state.scanHistory;
          final List<ScanResult> filteredScans = history.where((scan) {
             // Keep filtering logic same as before
            if (_searchQuery.isNotEmpty) { final query = _searchQuery.toLowerCase(); final matchesName = scan.pwdInfo.fullName.toLowerCase().contains(query); final matchesId = scan.pwdInfo.pwdNumber.toLowerCase().contains(query); final matchesEstablishment = scan.establishmentName.toLowerCase().contains(query); if (!(matchesName || matchesId || matchesEstablishment)) return false; }
            if (_showOnlyValid && !scan.isValid) return false; if (_showOnlyInvalid && scan.isValid) return false; if (_showOnlyUnsynced && scan.isSyncedWithServer) return false; if (_selectedDate != null) { final scanDate = DateTime(scan.scanTime.year, scan.scanTime.month, scan.scanTime.day); final filterDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day); if (scanDate != filterDate) return false; }
            return true;
          }).toList();

          if (filteredScans.isEmpty) {
            final bool hasActiveFilters = _searchQuery.isNotEmpty || _showOnlyValid || _showOnlyInvalid || _showOnlyUnsynced || _selectedDate != null;
            return _buildEmptyState(hasActiveFilters);
          }
          return _buildScanHistoryList(filteredScans);
        }
        else {
           return const AppLoader(); // Default fallback
        }
      },
    );
  }

  // Empty State - keep as is
  Widget _buildEmptyState(bool hasFilters) { return Center( child: Padding( padding: const EdgeInsets.all(24.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon( hasFilters ? Icons.filter_alt_off_outlined : Icons.history_toggle_off, size: 64, color: Colors.grey[400] ), const SizedBox(height: 16), Text( hasFilters ? 'No Results Found' : 'No Scan History Yet', textAlign: TextAlign.center, style: TextStyle( fontSize: 18, color: Colors.grey[600] ) ), const SizedBox(height: 8), Text( hasFilters ? 'Try adjusting your search or filter criteria.' : 'Scanned PWD QR codes will appear here.', textAlign: TextAlign.center, style: TextStyle( fontSize: 14, color: Colors.grey[500] ) ), if (hasFilters) Padding( padding: const EdgeInsets.only(top: 24.0), child: ElevatedButton.icon( icon: const Icon(Icons.clear_all), label: const Text('Clear Filters'), onPressed: _resetFilters, style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12) ) ) ), ], ), ), ); }

  // Scan History List - keep as is
  Widget _buildScanHistoryList(List<ScanResult> filteredScans) { final groupedScans = <String, List<ScanResult>>{}; for (final scan in filteredScans) { final dateKey = DateFormat('yyyy-MM-dd').format(scan.scanTime); if (!groupedScans.containsKey(dateKey)) groupedScans[dateKey] = []; groupedScans[dateKey]!.add(scan); } final sortedDateKeys = groupedScans.keys.toList()..sort((a, b) => b.compareTo(a)); return RefreshIndicator( onRefresh: () async { _scanBloc.add(const LoadScanHistory()); await Future.delayed(const Duration(milliseconds: 500)); }, child: ListView.builder( itemCount: sortedDateKeys.length, itemBuilder: (context, index) { final dateKey = sortedDateKeys[index]; final scansForDate = groupedScans[dateKey]!..sort((a, b) => b.scanTime.compareTo(a.scanTime)); return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Padding( padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text( _formatDateHeader(dateKey), style: TextStyle( fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color, ) ) ), ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: scansForDate.length, itemBuilder: (context, i) => _buildScanItem(scansForDate[i]), ), if (index < sortedDateKeys.length - 1) const Divider(height: 1, indent: 16, endIndent: 16), ], ); }, ), ); }

  // Scan Item - keep as is
  Widget _buildScanItem(ScanResult scan) { final bool isExpired = !scan.isValid && scan.invalidReason != null && scan.invalidReason!.toLowerCase().contains('expired'); final Color statusColor = isExpired ? Colors.orange : (scan.isValid ? Colors.green : Colors.red); final IconData statusIcon = isExpired ? Icons.history_toggle_off : (scan.isValid ? Icons.check_circle_outline : Icons.cancel_outlined); return ListTile( contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), leading: CircleAvatar( backgroundColor: statusColor.withOpacity(0.1), child: Icon( statusIcon, color: statusColor, size: 20) ), title: Text( scan.pwdInfo.fullName.isNotEmpty ? scan.pwdInfo.fullName : '(Name Not Available)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle( fontWeight: FontWeight.w600 ) ), subtitle: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const SizedBox(height: 2), Text( 'ID: ${scan.pwdInfo.pwdNumber.isNotEmpty ? scan.pwdInfo.pwdNumber : "(ID Not Available)"}', style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis ), const SizedBox(height: 4), Row( children: [ Icon(Icons.access_time, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text( DateFormat('hh:mm a').format(scan.scanTime), style: TextStyle(fontSize: 12, color: Colors.grey[600]) ), const Spacer(), if (!scan.isSyncedWithServer) Container( padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration( color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(4) ), child: Row( mainAxisSize: MainAxisSize.min, children: [ Icon( Icons.cloud_off, color: Colors.orange.shade800, size: 12), const SizedBox(width: 4), Text( 'Pending Sync', style: TextStyle( color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold ) ) ] ) ), ] ), if (!scan.isValid && scan.invalidReason != null && !isExpired) Padding( padding: const EdgeInsets.only(top: 4.0), child: Text( scan.invalidReason!, style: TextStyle(fontSize: 12, color: Colors.red.shade700), maxLines: 1, overflow: TextOverflow.ellipsis ) ), ] ), trailing: Icon(Icons.chevron_right, color: Colors.grey[400]), onTap: () { if(scan.pwdInfo.id.isNotEmpty || scan.pwdInfo.pwdNumber.isNotEmpty) { Navigator.pushNamed( context, '/verification_result', arguments: scan ); } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Cannot view details for this invalid scan.'), duration: Duration(seconds: 2)) ); } }, ); }

  // Filter Bottom Sheet - keep as is
  void _showFilterBottomSheet(BuildContext context) { bool tempShowValid = _showOnlyValid; bool tempShowInvalid = _showOnlyInvalid; bool tempShowUnsynced = _showOnlyUnsynced; DateTime? tempSelectedDate = _selectedDate; showModalBottomSheet( context: context, isScrollControlled: true, shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(16)) ), builder: (sheetContext) { return StatefulBuilder( builder: (BuildContext context, StateSetter setSheetState) { return Padding( padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 8 ), child: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Center( child: Container( width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)) ) ), Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Filter Scan History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton( onPressed: () { setSheetState(() { tempShowValid = false; tempShowInvalid = false; tempShowUnsynced = false; tempSelectedDate = null; }); }, child: const Text('Reset') ) ] ), const Divider(height: 24), const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Wrap( spacing: 8.0, children: [ FilterChip( label: const Text('Valid'), selected: tempShowValid, onSelected: (selected) { setSheetState(() { tempShowValid = selected; if (selected) tempShowInvalid = false; }); }, selectedColor: Colors.green.shade100, checkmarkColor: Colors.green ), FilterChip( label: const Text('Invalid'), selected: tempShowInvalid, onSelected: (selected) { setSheetState(() { tempShowInvalid = selected; if (selected) tempShowValid = false; }); }, selectedColor: Colors.red.shade100, checkmarkColor: Colors.red ) ] ), const SizedBox(height: 16), const Text('Sync Status', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), FilterChip( label: const Text('Unsynced Only'), selected: tempShowUnsynced, onSelected: (selected) => setSheetState(() => tempShowUnsynced = selected), selectedColor: Colors.orange.shade100, checkmarkColor: Colors.orange ), const SizedBox(height: 16), const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Row( children: [ Expanded( child: OutlinedButton.icon( icon: const Icon(Icons.calendar_today, size: 18), label: Text(tempSelectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(tempSelectedDate!)), onPressed: () async { final picked = await showDatePicker( context: context, initialDate: tempSelectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now() ); if (picked != null) { setSheetState(() => tempSelectedDate = picked); } }, style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 12) ) ) ), if (tempSelectedDate != null) IconButton( icon: const Icon(Icons.clear), tooltip: 'Clear Date Filter', onPressed: () => setSheetState(() => tempSelectedDate = null) ) ] ), const SizedBox(height: 24), SizedBox( width: double.infinity, child: ElevatedButton.icon( icon: const Icon(Icons.check), onPressed: () { setState(() { _showOnlyValid = tempShowValid; _showOnlyInvalid = tempShowInvalid; _showOnlyUnsynced = tempShowUnsynced; _selectedDate = tempSelectedDate; }); Navigator.pop(sheetContext); }, label: const Text('Apply Filters'), style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 14) ) ) ), const SizedBox(height: 16), ], ), ), ); }, ); }, ); }

  // Date Header Formatter - keep as is
  String _formatDateHeader(String dateString) { try { final now = DateTime.now(); final date = DateTime.parse(dateString); final today = DateTime(now.year, now.month, now.day); final yesterday = DateTime(now.year, now.month, now.day - 1); if (date == today) return 'Today'; else if (date == yesterday) return 'Yesterday'; else if (now.difference(date).inDays < 7 && date.weekday <= now.weekday) return DateFormat('EEEE').format(date); else return DateFormat('EEEE, MMMM d').format(date); } catch (e) { return dateString; } }

} // End of _ScanHistoryScreenState class