import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _displayNameController = TextEditingController();
  int _totalAlerts = 0;
  bool _isLoading = true;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final alerts = await _supabase
            .from('alerts')
            .select('id')
            .eq('user_id', user.id);
        setState(() {
          _totalAlerts = alerts.length;
          _displayNameController.text =
              user.userMetadata?['display_name'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateDisplayName() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': _displayNameController.text.trim(),
            },
          ),
        );
        setState(() => _isEditingName = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Display name updated")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update display name: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Email
              Text(
                "Email",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Unknown',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              
              // Display Name
              Text(
                "Display Name",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              _isEditingName
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _updateDisplayName,
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () =>
                              setState(() => _isEditingName = false),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayNameController.text.isEmpty
                                ? 'Not set'
                                : _displayNameController.text,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              setState(() => _isEditingName = true),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              
              // Date Joined
              Text(
                "Date Joined",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                user?.createdAt != null
                    ? DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(user!.createdAt!))
                    : 'Unknown',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              
              // Total Alerts
              Text(
                "Total Alerts Submitted",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _totalAlerts.toString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              
              // Logout Button
              GradientButton(
                text: "Logout",
                icon: Icons.logout,
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
