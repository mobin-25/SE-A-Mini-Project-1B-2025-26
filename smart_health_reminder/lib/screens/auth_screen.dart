import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/nebula_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_picker.dart';

/// Completer that _AppLoader can await to ensure sign-up writes finish
/// before trying to load the profile.
Completer<void>? signUpWritesCompleter;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;
  String _role = 'user'; // 'user' or 'doctor'
  int _avatarThemeIndex = 0; // index into kAvatarThemes
  int _avatarVariant = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _auth.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        // Check unique username before creating account
        final name = _nameCtrl.text.trim();
        final username = _usernameCtrl.text.trim().toLowerCase();

        // Check username availability (allows unauthenticated reads)
        final usernameDoc =
            await FirebaseFirestore.instance
                .collection('usernames')
                .doc(username)
                .get();
        if (usernameDoc.exists) {
          setState(() {
            _error =
                'The username "@$username" is already taken. Please choose a different one.';
            _loading = false;
          });
          return;
        }

        // Set up a completer so _AppLoader knows to wait for writes
        signUpWritesCompleter = Completer<void>();

        // Create the Firebase Auth account first
        final cred = await _auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

        // Now the user is authenticated — write all Firestore data
        if (cred.user != null) {
          try {
            final isDoctor = _role == 'doctor';
            final batch = FirebaseFirestore.instance.batch();

            // Generate avatar using selected theme
            final avatarSeed =
                _avatarVariant == 0 ? username : '${username}_v$_avatarVariant';
            final avatarUrl = kAvatarThemes[_avatarThemeIndex].generateUrl(
              avatarSeed,
            );

            // Reserve the username
            batch.set(
              FirebaseFirestore.instance.collection('usernames').doc(username),
              {'uid': cred.user!.uid, 'name': name},
            );

            // Create the user profile
            batch.set(
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(cred.user!.uid)
                  .collection('profile')
                  .doc('default_user'),
              {
                'id': cred.user!.uid,
                'name': name,
                'username': username,
                'role': _role,
                'onboardingComplete': isDoctor,
                'healthConditions': <String>[],
                'allergies': <String>[],
                'profilePicture': avatarUrl,
              },
            );

            // If doctor, also create doctorProfiles entry
            if (isDoctor) {
              batch.set(
                FirebaseFirestore.instance
                    .collection('doctorProfiles')
                    .doc(cred.user!.uid),
                {
                  'id': cred.user!.uid,
                  'name': name,
                  'username': username,
                  'specialty': '',
                  'phone': '',
                  'email': _emailCtrl.text.trim(),
                  'bio': '',
                  'availability': [],
                  'profilePicture': avatarUrl,
                },
              );
            }

            // Commit all writes atomically
            await batch.commit();
          } finally {
            // Signal that writes are done (success or failure)
            signUpWritesCompleter?.complete();
            signUpWritesCompleter = null;
          }
        } else {
          signUpWritesCompleter?.complete();
          signUpWritesCompleter = null;
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyError(e.code);
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(
        () => _error = 'Enter your email first, then tap Forgot Password.',
      );
      return;
    }
    try {
      await _auth.resetPassword(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.accentGradient,
                      boxShadow: AppTheme.glow(
                        AppTheme.electricBlue,
                        blur: 24,
                        spread: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MEDITOUCH',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: AppTheme.electricBlue.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLogin ? 'Welcome back' : 'Create your account',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name (sign up only)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: _inputDecor(
                                'Full Name',
                                Icons.person_outline,
                              ),
                              validator: (v) {
                                if (!_isLogin &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Enter your name';
                                }
                                if (!_isLogin &&
                                    v != null &&
                                    v.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Username (like Instagram)
                            TextFormField(
                              controller: _usernameCtrl,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: _inputDecor(
                                'Username',
                                Icons.alternate_email,
                              ).copyWith(
                                hintText: 'e.g. john_doe',
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (!_isLogin &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Choose a username';
                                }
                                if (!_isLogin && v != null) {
                                  final trimmed = v.trim();
                                  if (trimmed.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9._]+$',
                                  ).hasMatch(trimmed)) {
                                    return 'Only letters, numbers, dots and underscores';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecor(
                              'Email',
                              Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecor(
                              'Password',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _obscurePass = !_obscurePass,
                                    ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Confirm password (sign up only)
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: _inputDecor(
                                'Confirm Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Role selector
                            Row(
                              children: [
                                const Text(
                                  'I am a:',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _RoleChip(
                                        label: 'Patient',
                                        icon: Icons.person_outline,
                                        selected: _role == 'user',
                                        onTap:
                                            () =>
                                                setState(() => _role = 'user'),
                                      ),
                                      const SizedBox(width: 10),
                                      _RoleChip(
                                        label: 'Doctor',
                                        icon: Icons.medical_services_outlined,
                                        selected: _role == 'doctor',
                                        onTap:
                                            () => setState(
                                              () => _role = 'doctor',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Avatar style picker
                            const SizedBox(height: 20),
                            const Text(
                              'Pick your avatar style:',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Preview current avatar
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.accentGradient,
                                  boxShadow: AppTheme.glow(
                                    kAvatarThemes[_avatarThemeIndex].color,
                                    blur: 14,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppTheme.bgPrimary,
                                  backgroundImage: NetworkImage(
                                    kAvatarThemes[_avatarThemeIndex].generateUrl(
                                      _avatarVariant == 0
                                          ? (_usernameCtrl.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? _usernameCtrl.text
                                                  .trim()
                                                  .toLowerCase()
                                              : 'default')
                                          : '${_usernameCtrl.text.trim().toLowerCase()}_v$_avatarVariant',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Horizontal theme selector
                            SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: kAvatarThemes.length,
                                itemBuilder: (_, i) {
                                  final t = kAvatarThemes[i];
                                  final isSelected = i == _avatarThemeIndex;
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _avatarThemeIndex = i,
                                        ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color:
                                            isSelected
                                                ? t.color.withValues(alpha: 0.2)
                                                : AppTheme.glassWhite,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? t.color
                                                  : AppTheme.glassBorder,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            t.icon,
                                            size: 16,
                                            color: t.color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            t.name,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? t.color
                                                      : AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Variant selector
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 6,
                                itemBuilder: (_, i) {
                                  final isSelected = i == _avatarVariant;
                                  return GestureDetector(
                                    onTap:
                                        () =>
                                            setState(() => _avatarVariant = i),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? kAvatarThemes[_avatarThemeIndex]
                                                      .color
                                                  : AppTheme.glassBorder,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.bgPrimary,
                                        backgroundImage: NetworkImage(
                                          kAvatarThemes[_avatarThemeIndex]
                                              .generateUrl(
                                                i == 0
                                                    ? (_usernameCtrl.text
                                                            .trim()
                                                            .isNotEmpty
                                                        ? _usernameCtrl.text
                                                            .trim()
                                                            .toLowerCase()
                                                        : 'default')
                                                    : '${_usernameCtrl.text.trim().isNotEmpty ? _usernameCtrl.text.trim().toLowerCase() : 'default'}_v$i',
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.radiantPink.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.radiantPink.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.radiantPink,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppTheme.radiantPink,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Forgot password (login only)
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppTheme.electricBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: AppTheme.accentGradient,
                                boxShadow: AppTheme.glow(
                                  AppTheme.electricBlue,
                                  blur: 16,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child:
                                    _loading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Text(
                                          _isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Toggle login/signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      filled: true,
      fillColor: AppTheme.glassWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.electricBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.radiantPink),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppTheme.electricBlue.withValues(alpha: 0.2)
                    : AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.electricBlue : AppTheme.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    selected ? AppTheme.electricBlue : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? AppTheme.electricBlue : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
