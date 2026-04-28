import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert.dart';

import 'image_viewer_screen.dart';

class AlertDetailScreen extends StatefulWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Alert _alert;
  final TextEditingController _messageController = TextEditingController();
  String _selectedStatus = 'Open';
  bool _isEditing = false;
  bool _isLoading = false;

  final List<String> _statuses = ['Open', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
    _messageController.text = _alert.message;
    _selectedStatus = _alert.status;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.yellow;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'In Progress':
        return Colors.purple;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateAlert() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('alerts').update({
        'message': _messageController.text.trim(),
        'status': _selectedStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _alert.id);

      setState(() {
        _alert = _alert.copyWith(
          message: _messageController.text.trim(),
          status: _selectedStatus,
          updatedAt: DateTime.now(),
        );
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alert updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update alert: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteAlert() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Alert"),
        content: const Text("Are you sure you want to delete this alert?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _supabase.from('alerts').delete().eq('id', _alert.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Alert deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete alert: $e")),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Alert Details",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          if (_alert.userId == _supabase.auth.currentUser?.id)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_isEditing) {
                        _updateAlert();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
            ),
          if (_alert.userId == _supabase.auth.currentUser?.id)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _deleteAlert,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPriorityColor(_alert.priority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getPriorityColor(_alert.priority)),
              ),
              child: Text(
                _alert.priority,
                style: TextStyle(
                  color: _getPriorityColor(_alert.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message
            Text(
              "Message",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_alert.message),
                  ),
            const SizedBox(height: 16),
            // Status
            Text(
              "Status",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _isEditing
                ? DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedStatus = value!),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_alert.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(_alert.status)),
                    ),
                    child: Text(
                      _alert.status,
                      style: TextStyle(
                        color: _getStatusColor(_alert.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            // Image
            if (_alert.imageUrl != null) ...[
              Text(
                "Image",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewerScreen(imageUrl: _alert.imageUrl!),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _alert.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Timestamps
            Text(
              "Created",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(_alert.createdAt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Last Updated",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(_alert.updatedAt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // User
            Text(
              "Reported by",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _alert.userEmail ?? 'Unknown',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

extension on Alert {
  Alert copyWith({
    String? id,
    String? message,
    String? imageUrl,
    String? userId,
    String? userEmail,
    String? priority,
    String? status,
    double? latitude,
    double? longitude,
    String? locationAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}