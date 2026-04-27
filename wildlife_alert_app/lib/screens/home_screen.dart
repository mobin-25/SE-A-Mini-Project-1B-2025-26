import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alert.dart';
import '../widgets/alert_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_page_route.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'alert_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  File? _image;
  String _selectedPriority = 'Medium';
  int _currentIndex = 0;
  String _searchQuery = '';
  String _priorityFilter = 'All';
  String _statusFilter = 'All';
  bool _isMapView = false;
  Position? _currentPosition;
  bool _isLocating = true;       // true while initial GPS permission/fetch is in progress
  bool _isFetchingLocation = false; // true while fetching GPS for an alert submission
  List<Alert> _alerts = [];
  bool _isLoading = true;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadAlerts();
    _startRealtime();
    // Initialise local notifications (no-op if already done)
    NotificationService.initialize();
  }

  /// Subscribes to Supabase Realtime on the alerts table.
  /// • Refreshes the alert list for EVERY user.
  /// • Shows a local notification for alerts submitted by OTHER users.
  void _startRealtime() {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    _realtimeChannel = _supabase
        .channel('public:alerts:home')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            // Refresh list for everyone
            _loadAlerts();

            // Show notification only for other users' alerts
            final insertedBy =
                payload.newRecord['user_id']?.toString() ?? '';
            if (insertedBy != currentUserId) {
              final message = payload.newRecord['message']?.toString() ??
                  'Wild animal sighted!';
              NotificationService.showNotification(
                title: '🚨 New Wildlife Alert',
                body: message,
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await LocationService.requestPermission();
      if (hasPermission) {
        _currentPosition = await LocationService.getCurrentPosition();
      }
    } finally {
      // Always hide the banner whether we got a position or not
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Fetches a fresh GPS fix on demand (e.g. right before submitting an alert).
  Future<void> _captureLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    try {
      final status = await LocationService.checkStatus();

      if (status == LocationPermissionStatus.permanentlyDenied) {
        // Can't request again — must send user to settings
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location access has been permanently denied.\n\n'
              'To attach your location to alerts, please open Settings and '
              'enable "Location" for this app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  LocationService.openSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }

      if (status == LocationPermissionStatus.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permission denied. Alert will be submitted without location.')),
          );
        }
        return;
      }

      // Granted — get the position
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && mounted) setState(() => _currentPosition = pos);
    } catch (_) {
      // ignore — submit without location
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);

    // All columns we'd like; optional ones (model has null/default fallbacks)
    // are listed first so they can be pruned without breaking core functionality.
    const fullSelect =
        'id, message, image_url, user_id, user_email, priority, status, '
        'latitude, longitude, location_address, created_at, updated_at';

    // Every column the DB might not have yet — pruned automatically on error.
    const optionalColumns = {
      'status', 'priority', 'updated_at',
      'latitude', 'longitude', 'location_address',
      'image_url', 'user_email',
    };

    var currentSelect = fullSelect;
    var orderByCreatedAt = true; // disable if created_at is also absent
    Object? lastError;

    // Retry up to 8 times, stripping one missing column per attempt.
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final query = _supabase.from('alerts').select(currentSelect);
        final response = orderByCreatedAt
            ? await query.order('created_at', ascending: false)
            : await query;
        _alerts =
            (response as List).map((json) => Alert.fromJson(json)).toList();
        lastError = null; // success — clear any previous error
        break;
      } catch (e) {
        if (!_isMissingSchemaColumnError(e)) {
          lastError = e;
          break; // non-recoverable — stop retrying
        }

        final errorMessage =
            e is PostgrestException ? e.message : e.toString();
        var missing = _extractMissingColumns(errorMessage);

        // If we can't parse the column name, strip all known optional ones.
        if (missing.isEmpty) {
          missing = optionalColumns.toList();
        }

        // Special case: if created_at is missing, drop the ORDER BY instead.
        if (missing.contains('created_at')) {
          orderByCreatedAt = false;
          missing = missing.where((c) => c != 'created_at').toList();
        }

        final fields = currentSelect.split(',').map((f) => f.trim()).toList();
        final pruned =
            fields.where((f) => !missing.contains(f)).join(', ');

        if (pruned == currentSelect || pruned.isEmpty) {
          lastError = e; // no progress possible — surface the error
          break;
        }
        currentSelect = pruned;
        lastError = e; // will be cleared if next attempt succeeds
      }
    }

    if (lastError != null && mounted) {
      final msg = lastError is PostgrestException
          ? lastError.message
          : lastError.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load alerts: $msg')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _insertAlertPayload(Map<String, dynamic> payload) async {
    var fallbackPayload = Map<String, dynamic>.from(payload);

    // Columns the basic alerts table might not have yet.
    // If ANY schema-cache error occurs we strip all of them at once
    // so we don't waste multiple retries on each one individually.
    const optionalColumns = [
      'latitude', 'longitude', 'location_address',
      'status', 'priority', 'image_url', 'updated_at',
    ];

    Object? lastError;

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await _supabase.from('alerts').insert(fallbackPayload);
        return; // success
      } catch (e) {
        if (!_isMissingSchemaColumnError(e)) {
          rethrow;
        }

        lastError = e;

        // Extract named columns from both message and details
        final errorText = _fullErrorText(e);
        var missingColumns = _extractMissingColumns(errorText);

        // If the error just says "schema cache" without naming a column,
        // strip all optional columns at once.
        if (missingColumns.isEmpty) {
          missingColumns = List<String>.from(optionalColumns);
        }

        final before = fallbackPayload.length;
        for (final col in missingColumns) {
          fallbackPayload.remove(col);
        }

        // If nothing was removed we can't make progress — give up
        if (fallbackPayload.length == before || fallbackPayload.isEmpty) {
          rethrow;
        }
      }
    }

    if (lastError != null) throw lastError;
  }

  /// Returns the combined error text from both message and details fields.
  String _fullErrorText(Object e) {
    if (e is PostgrestException) {
      return '${e.message} ${e.details ?? ""}';
    }
    return e.toString();
  }

  bool _isMissingSchemaColumnError(Object e) {
    final message = _fullErrorText(e);
    return message.contains("Could not find the '") ||
        message.contains('Could not find column') ||
        message.contains('Could not find the column') ||
        message.contains('schema cache') ||
        message.contains('does not exist');
  }

  List<String> _extractMissingColumns(String message) {
    final patterns = [
      RegExp(r"Could not find the '([^']+)' column", caseSensitive: false),
      RegExp(r'Could not find column "([^"]+)"', caseSensitive: false),
      RegExp(r"Could not find the column '([^']+)'", caseSensitive: false),
      // PostgreSQL native: "column alerts.status does not exist"
      RegExp(r'column (?:\w+\.)?(\w+) does not exist', caseSensitive: false),
    ];

    final columns = <String>{};
    for (final regex in patterns) {
      for (final match in regex.allMatches(message)) {
        final name = match.group(1);
        // Skip table names (e.g. 'alerts' extracted from "column of 'alerts'")
        if (name != null && name.isNotEmpty && name != 'alerts') {
          columns.add(name.trim());
        }
      }
    }

    return columns.toList();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<String?> uploadImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final path = 'alerts/$userId/$fileName';

      await _supabase.storage.from('alert-images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('alert-images').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> addAlert() async {
    if (_messageController.text.trim().isEmpty && _image == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a message or attach an image to submit an alert.")),
        );
      }
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please sign in before submitting an alert.")),
        );
      }
      return;
    }

    String? imageUrl;
    if (_image != null) imageUrl = await uploadImage(_image!);

    // Try to get location if we don't have it yet
    if (_currentPosition == null) await _captureLocation();

    String? address;
    if (_currentPosition != null) {
      address = await LocationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    final payload = {
      'message': _messageController.text.trim().isEmpty
          ? 'Wild animal sighted!'
          : _messageController.text.trim(),
      'image_url': imageUrl,
      'user_id': user.id,
      'user_email': user.email,
      'priority': _selectedPriority,
      'status': 'Open',
      if (_currentPosition != null) 'latitude': _currentPosition!.latitude,
      if (_currentPosition != null) 'longitude': _currentPosition!.longitude,
      if (address != null) 'location_address': address,
    };

    try {
      await _insertAlertPayload(payload);

      _messageController.clear();
      setState(() {
        _image = null;
        _selectedPriority = 'Medium';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alert submitted successfully.")),
        );
      }
    } catch (e) {
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add alert: $message")),
        );
      }
      return;
    }

    try {
      await _loadAlerts();
    } catch (e) {
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Alert added, but refresh failed: $message")),
        );
      }
    }
  }

  Future<void> addQuickAlert() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please sign in before submitting an alert.")),
        );
      }
      return;
    }

    // Try to get location if we don't have it yet
    if (_currentPosition == null) await _captureLocation();

    String? address;
    if (_currentPosition != null) {
      address = await LocationService.getAddressFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);
    }

    final payload = {
      'message': 'SOS — Immediate help needed',
      'user_id': user.id,
      'user_email': user.email,
      'priority': 'Critical',
      'status': 'Open',
      if (_currentPosition != null) 'latitude': _currentPosition!.latitude,
      if (_currentPosition != null) 'longitude': _currentPosition!.longitude,
      if (address != null) 'location_address': address,
    };

    try {
      await _insertAlertPayload(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS alert sent!")),
        );
      }
    } catch (e) {
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send SOS alert: $message")),
        );
      }
      return;
    }

    try {
      await _loadAlerts();
    } catch (e) {
      final message = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SOS alert sent, but refresh failed: $message")),
        );
      }
    }
  }

  List<Alert> _filterAlerts(List<Alert> alerts) {
    return alerts.where((alert) {
      final matchesSearch = _searchQuery.isEmpty ||
          alert.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (alert.userEmail?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (alert.locationAddress?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesPriority = _priorityFilter == 'All' || alert.priority == _priorityFilter;
      final matchesStatus = _statusFilter == 'All' || alert.status == _statusFilter;
      return matchesSearch && matchesPriority && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    NotificationService.stopListening();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.accentTeal),
            const SizedBox(width: 8),
            Text(
              "Wildlife Alert",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: Icon(_isMapView ? Icons.list : Icons.map),
              onPressed: () => setState(() => _isMapView = !_isMapView),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notification bell - for now just a placeholder
            },
          ),
          CircleAvatar(
            backgroundColor: AppTheme.accentTeal,
            child: Text(
              _supabase.auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildHomeContent()
            : _currentIndex == 1
                ? _buildMapView()
                : const ProfileScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        backgroundColor: AppTheme.error,
        onPressed: addQuickAlert,
        child: const Icon(Icons.sos, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Create Alert Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: "Describe wildlife sighting",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedPriority),
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
              const SizedBox(height: 12),
              // Location status chip
              InkWell(
                onTap: _isFetchingLocation ? null : _captureLocation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentPosition != null
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _currentPosition != null
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isFetchingLocation)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _currentPosition != null
                              ? Icons.location_on
                              : Icons.location_off,
                          size: 16,
                          color: _currentPosition != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _isFetchingLocation
                            ? 'Getting location…'
                            : _currentPosition != null
                                ? '📍 Location ready'
                                : '⚠️ No location — tap to retry',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _currentPosition != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_image != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_image!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: "Pick Image",
                      icon: Icons.image,
                      onPressed: pickImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      text: "Submit Alert",
                      icon: Icons.send,
                      onPressed: addAlert,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GradientButton(
                text: "Quick Alert",
                icon: Icons.add_alert,
                onPressed: addQuickAlert,
              ),
            ],
          ),
        ),
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Search alerts...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('priority_$_priorityFilter'),
                      initialValue: _priorityFilter,
                      decoration: InputDecoration(
                        labelText: "Priority",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', ..._priorities].map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _priorityFilter = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('status_$_statusFilter'),
                      initialValue: _statusFilter,
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', 'Open', 'In Progress', 'Resolved'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _statusFilter = value!),
                    ),
                  ),
                ],
              ),
              // Clear filters button — visible only when a filter is active
              if (_searchQuery.isNotEmpty || _priorityFilter != 'All' || _statusFilter != 'All')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _priorityFilter = 'All';
                        _statusFilter = 'All';
                      }),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Alerts List
        Expanded(
          child: _isLoading
              ? _buildShimmerLoader()
              : _filterAlerts(_alerts).isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filterAlerts(_alerts).length,
                      itemBuilder: (context, index) {
                        final alert = _filterAlerts(_alerts)[index];
                        return AlertCard(
                          data: alert.toJson(),
                          onTap: () => Navigator.push(
                            context,
                            FadeSlidePageRoute(page: AlertDetailScreen(alert: alert)),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 150, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _priorityFilter != 'All' || _statusFilter != 'All';

  Widget _buildEmptyState() {
    final isFiltered = _hasActiveFilters && _alerts.isNotEmpty;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFiltered ? Icons.search_off : Icons.warning_amber,
                  size: 64,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isFiltered ? 'No matching alerts' : 'No alerts yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'Try adjusting your search or filters.'
                      : 'Tap + to create one.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isFiltered) ...[  
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _priorityFilter = 'All';
                      _statusFilter = 'All';
                    }),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629);

    final geoAlerts = _alerts.where((a) => a.latitude != null && a.longitude != null).toList();

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: _currentPosition != null ? 13 : 5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.wildlife_alert_app',
              tileProvider: NetworkTileProvider(),
              maxZoom: 19,
              keepBuffer: 4,
              errorTileCallback: (tile, error, stackTrace) =>
                  debugPrint('Map tile error: $error'),
            ),
            // Alert pins
            MarkerLayer(
              markers: geoAlerts.map((alert) => Marker(
                point: LatLng(alert.latitude!, alert.longitude!),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    FadeSlidePageRoute(page: AlertDetailScreen(alert: alert)),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.priorityColor(alert.priority),
                    child: Text(
                      alert.priority.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            // Current location dot
            if (_currentPosition != null)
              MarkerLayer(markers: [
                Marker(
                  point: center,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
          ],
        ),

        // ── Location acquiring banner ─────────────────────────────────────
        if (_isLocating)
          Positioned(
            top: 12, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Acquiring location…',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

        // ── Draggable bottom alerts panel ─────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.18,
          minChildSize: 0.10,
          maxChildSize: 0.55,
          snap: true,
          snapSizes: const [0.18, 0.55],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.accentTeal, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${geoAlerts.length} pinned · ${_alerts.length} total alerts',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Divider
                  const Divider(height: 1),
                  // Alert list
                  Expanded(
                    child: _alerts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber,
                                      size: 40,
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                                  const SizedBox(height: 8),
                                  const Text('No alerts yet — submit one from Home'),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _alerts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                            itemBuilder: (context, index) {
                              final alert = _alerts[index];
                              final hasLocation = alert.latitude != null;
                              return ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  FadeSlidePageRoute(page: AlertDetailScreen(alert: alert)),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.priorityColor(alert.priority),
                                  child: Text(
                                    alert.priority.substring(0, 1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  alert.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  hasLocation
                                      ? (alert.locationAddress ?? '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}')
                                      : 'No location data',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasLocation
                                        ? null
                                        : Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                                  ),
                                ),
                                trailing: Icon(
                                  hasLocation ? Icons.location_on : Icons.location_off,
                                  size: 18,
                                  color: hasLocation
                                      ? AppTheme.accentTeal
                                      : Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
