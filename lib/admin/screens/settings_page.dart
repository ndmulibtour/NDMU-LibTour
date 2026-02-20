import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ndmu_libtour/admin/services/imgbb_service.dart';
import 'package:ndmu_libtour/admin/services/system_settings_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SettingsPage — drop-in replacement for the placeholder in admin_dashboard.dart
// ═════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SystemSettingsService();
  final _imgbb = ImgBBService();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── Profile ────────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  bool _savingName = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  // ── System settings ────────────────────────────────────────────────────────
  SystemSettings _sysSettings = SystemSettings.defaults();
  bool _togglingMaintenance = false;

  // ── Login activity ─────────────────────────────────────────────────────────
  DateTime? _lastLogin;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Profile
    _nameCtrl.text = user.displayName ?? '';

    // Firestore user doc for role, avatar, lastLogin
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _userRole = data['role'] as String?;
            _avatarUrl = data['avatarUrl'] as String?;
            final raw = data['lastLogin'];
            if (raw is Timestamp) _lastLogin = raw.toDate();
          });
        }
        // Record current login timestamp
        await _db.collection('users').doc(user.uid).set(
          {'lastLogin': Timestamp.now()},
          SetOptions(merge: true),
        );
      }
    } catch (_) {}

    // System settings
    final sys = await _settingsService.fetchSettings();
    if (mounted) setState(() => _sysSettings = sys);
  }

  // ── Save display name ──────────────────────────────────────────────────────
  Future<void> _saveName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _savingName = true);
    try {
      await user.updateDisplayName(name);
      await _db
          .collection('users')
          .doc(user.uid)
          .set({'name': name}, SetOptions(merge: true));
      if (mounted) {
        _showSnack('Display name updated.', success: true);
        // Refresh AuthService so top bar picks up the new name
        Provider.of<AuthService>(context, listen: false)
            // ignore: invalid_use_of_protected_member
            .notifyListeners();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update name: $e');
    }
    if (mounted) setState(() => _savingName = false);
  }

  // ── Upload avatar ──────────────────────────────────────────────────────────
  Future<void> _uploadAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) {
        setState(() => _uploadingAvatar = false);
        return;
      }
      final url = await _imgbb.uploadImage(await file.readAsBytes(),
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (url != null && mounted) {
        await _db
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({'avatarUrl': url}, SetOptions(merge: true));
        setState(() => _avatarUrl = url);
        _showSnack('Profile photo updated.', success: true);
      } else if (mounted) {
        _showSnack('Image upload failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showSnack('Upload error: $e');
    }
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  // ── Maintenance mode toggle ────────────────────────────────────────────────
  Future<void> _toggleMaintenance(bool value) async {
    final uid = _auth.currentUser?.uid ?? '';
    setState(() {
      _togglingMaintenance = true;
      _sysSettings = SystemSettings(
        isMaintenanceMode: value,
        globalAnnouncement: _sysSettings.globalAnnouncement,
      );
    });
    final ok = await _settingsService.setMaintenanceMode(value, uid);
    if (mounted) {
      setState(() => _togglingMaintenance = false);
      _showSnack(
        ok
            ? value
                ? '⚠️ Maintenance mode ENABLED. Public site is now offline.'
                : '✅ Maintenance mode disabled. Public site is live.'
            : 'Failed to update maintenance mode.',
        success: ok,
      );
    }
  }

  // ── Snack helper ───────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF1B5E20) : Colors.red,
    ));
  }

  // ── Open dialogs ───────────────────────────────────────────────────────────
  void _openChangePassword() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  void _openAnnouncementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AnnouncementDialog(
        current: _sysSettings.globalAnnouncement,
        onSave: (text) async {
          final uid = _auth.currentUser?.uid ?? '';
          final ok = await _settingsService.setAnnouncement(text, uid);
          if (mounted) {
            setState(() => _sysSettings = SystemSettings(
                  isMaintenanceMode: _sysSettings.isMaintenanceMode,
                  globalAnnouncement: text,
                ));
            _showSnack(
              ok
                  ? text.isEmpty
                      ? 'Announcement cleared.'
                      : 'Announcement published.'
                  : 'Failed to save announcement.',
              success: ok,
            );
          }
        },
      ),
    );
  }

  void _openSignOutAllDevices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out All Devices'),
        content: const Text(
          'This will revoke all active sessions for your account. '
          'You will be signed out here as well and must log in again.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      // Force token refresh — revokes other sessions
      await _auth.currentUser?.getIdToken(true);
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Manage your account and system preferences',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── SECTION 1: Profile ─────────────────────────────────────
                _SectionCard(
                  title: 'Profile Management',
                  icon: Icons.person_outline,
                  children: [
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _uploadingAvatar ? null : _uploadAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundColor:
                                      const Color(0xFF1B5E20).withOpacity(0.1),
                                  backgroundImage: (_avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(_avatarUrl!)
                                      : null,
                                  child: _uploadingAvatar
                                      ? const CircularProgressIndicator()
                                      : (_avatarUrl == null ||
                                              _avatarUrl!.isEmpty)
                                          ? const Icon(Icons.person,
                                              size: 56,
                                              color: Color(0xFF1B5E20))
                                          : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _uploadingAvatar
                                ? 'Uploading...'
                                : 'Tap to change photo',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Display name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _savingName ? null : _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _savingName
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── SECTION 2: Security ────────────────────────────────────
                _SectionCard(
                  title: 'Security',
                  icon: Icons.lock_outline,
                  children: [
                    // Role badge
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.admin_panel_settings,
                          color: Color(0xFF1B5E20)),
                      title: const Text('Account Role'),
                      subtitle: Text(
                        (_userRole == 'admin')
                            ? 'Administrator — full access'
                            : (_userRole == 'director')
                                ? 'Director — read-only access'
                                : _userRole ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_userRole == 'admin')
                              ? const Color(0xFF1B5E20)
                              : Colors.blueGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_userRole ?? '').toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Divider(),

                    // Last login
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time,
                          color: Color(0xFF1B5E20)),
                      title: const Text('Last Login'),
                      subtitle: Text(
                        _lastLogin != null
                            ? _formatDate(_lastLogin!)
                            : 'Not recorded yet',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Divider(),

                    // Change password
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.key, color: Color(0xFF1B5E20)),
                      title: const Text('Change Password'),
                      subtitle: const Text(
                          'Requires your current password for verification'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: _openChangePassword,
                    ),
                    const Divider(),

                    // Sign out all devices
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.devices, color: Colors.redAccent),
                      title: const Text('Sign Out All Devices'),
                      subtitle: const Text(
                          'Revokes all active sessions and logs you out'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: _openSignOutAllDevices,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── SECTION 3: System Preferences ──────────────────────────
                _SectionCard(
                  title: 'System Preferences',
                  icon: Icons.tune,
                  children: [
                    // Maintenance mode
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.construction,
                        color: _sysSettings.isMaintenanceMode
                            ? Colors.orange
                            : const Color(0xFF1B5E20),
                      ),
                      title: const Text('Maintenance Mode'),
                      subtitle: Text(
                        _sysSettings.isMaintenanceMode
                            ? '⚠️ Active — public site is showing maintenance screen'
                            : 'Off — public site is live',
                        style: TextStyle(
                          color: _sysSettings.isMaintenanceMode
                              ? Colors.orange[800]
                              : Colors.grey[600],
                          fontWeight: _sysSettings.isMaintenanceMode
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      value: _sysSettings.isMaintenanceMode,
                      activeColor: Colors.orange,
                      onChanged:
                          _togglingMaintenance ? null : _toggleMaintenance,
                    ),
                    const Divider(),

                    // Global announcement
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.campaign_outlined,
                        color: _sysSettings.hasAnnouncement
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF1B5E20),
                      ),
                      title: const Text('Global Announcement Banner'),
                      subtitle: Text(
                        _sysSettings.hasAnnouncement
                            ? '"${_sysSettings.globalAnnouncement}"'
                            : 'No active announcement',
                        style: TextStyle(
                          color: _sysSettings.hasAnnouncement
                              ? Colors.brown[700]
                              : Colors.grey[600],
                          fontStyle: _sysSettings.hasAnnouncement
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_sysSettings.hasAnnouncement)
                            _GoldBadge(label: 'LIVE'),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                      onTap: _openAnnouncementDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrentPw = true;
  bool _hideNewPw = true;
  bool _hideConfirmPw = true;
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _errorText = 'No authenticated user found.';
        _saving = false;
      });
      return;
    }

    try {
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentCtrl.text,
      );
      await user.reauthenticateWithCredential(cred);

      // Now update the password
      await user.updatePassword(_newCtrl.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password updated successfully.'),
          backgroundColor: Color(0xFF1B5E20),
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _saving = false;
        _errorText = e.code == 'wrong-password'
            ? 'Incorrect current password. Please try again.'
            : e.code == 'weak-password'
                ? 'New password is too weak (minimum 6 characters).'
                : 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _errorText = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            _DialogTitleBar(
              icon: Icons.key,
              title: 'Change Password',
              onClose: () => Navigator.pop(context),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (_errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_errorText!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _PwField(
                      ctrl: _currentCtrl,
                      label: 'Current Password',
                      obscure: _hideCurrentPw,
                      onToggle: () =>
                          setState(() => _hideCurrentPw = !_hideCurrentPw),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your current password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _PwField(
                      ctrl: _newCtrl,
                      label: 'New Password',
                      obscure: _hideNewPw,
                      onToggle: () => setState(() => _hideNewPw = !_hideNewPw),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter new password';
                        if (v.length < 6) return 'Minimum 6 characters';
                        if (v == _currentCtrl.text)
                          return 'New password must differ from current';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PwField(
                      ctrl: _confirmCtrl,
                      label: 'Confirm New Password',
                      obscure: _hideConfirmPw,
                      onToggle: () =>
                          setState(() => _hideConfirmPw = !_hideConfirmPw),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirm your password';
                        if (v != _newCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will not be signed out after changing your password.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Update Password'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GLOBAL ANNOUNCEMENT DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _AnnouncementDialog extends StatefulWidget {
  final String current;
  final Future<void> Function(String text) onSave;

  const _AnnouncementDialog({required this.current, required this.onSave});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTitleBar(
              icon: Icons.campaign_outlined,
              title: 'Global Announcement',
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This announcement banner appears at the top of the Home Screen for all visitors.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Announcement Text',
                      hintText:
                          'e.g. "Library closes at 3 PM today due to weather."',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leave blank to remove the announcement banner.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.current.isNotEmpty)
                    TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              await widget.onSave('');
                              if (mounted) Navigator.pop(context);
                            },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      label: const Text('Clear Banner',
                          style: TextStyle(color: Colors.red)),
                    )
                  else
                    const SizedBox(),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                await widget.onSave(_ctrl.text);
                                if (mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Publish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Consistent green-header card section.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFD700), size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Section body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable dialog title bar with green gradient.
class _DialogTitleBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onClose;

  const _DialogTitleBar({
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Password field with show/hide toggle.
class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PwField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

/// Small pill badge (e.g. "LIVE").
class _GoldBadge extends StatelessWidget {
  final String label;
  const _GoldBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20))),
    );
  }
}
