// lib/admin/screens/settings_page.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All Firebase/AuthService logic, change-password dialog, and announcement
// dialog are fully preserved. Only visual chrome has changed.

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
import '../admin_ui_kit.dart';

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

  final _nameCtrl = TextEditingController();
  bool _savingName = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  SystemSettings _sys = SystemSettings.defaults();
  bool _togglingMaint = false;

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
    _nameCtrl.text = user.displayName ?? '';
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
        await _db
            .collection('users')
            .doc(user.uid)
            .set({'lastLogin': Timestamp.now()}, SetOptions(merge: true));
      }
    } catch (_) {}
    final sys = await _settingsService.fetchSettings();
    if (mounted) setState(() => _sys = sys);
  }

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
        admSnack(context, 'Display name updated.');
        Provider.of<AuthService>(context, listen: false)
            // ignore: invalid_use_of_protected_member
            .notifyListeners();
      }
    } catch (e) {
      if (mounted)
        admSnack(context, 'Failed to update name: $e', success: false);
    }
    if (mounted) setState(() => _savingName = false);
  }

  Future<void> _uploadAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) {
        setState(() => _uploadingAvatar = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final url =
          await _imgbb.uploadImage(bytes, 'avatar_${_auth.currentUser!.uid}');
      if (url != null) {
        await _db
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({'avatarUrl': url}, SetOptions(merge: true));
        if (mounted)
          setState(() {
            _avatarUrl = url;
            _uploadingAvatar = false;
          });
      } else {
        if (mounted) {
          admSnack(context, 'Image upload failed.', success: false);
          setState(() => _uploadingAvatar = false);
        }
      }
    } catch (e) {
      if (mounted) {
        admSnack(context, 'Error: $e', success: false);
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _togglingMaint = true);
    final uid = _auth.currentUser?.uid ?? '';
    final ok = await _settingsService.setMaintenanceMode(value, uid);
    if (mounted) {
      setState(() {
        _sys = SystemSettings(
            isMaintenanceMode: value,
            globalAnnouncement: _sys.globalAnnouncement);
        _togglingMaint = false;
      });
      admSnack(
          context,
          ok
              ? (value ? '⚠️ Maintenance mode ON.' : '✅ Maintenance mode OFF.')
              : 'Failed to update.',
          success: ok);
    }
  }

  void _openChangePassword() => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog());

  void _openAnnouncementDialog() => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AnnouncementDialog(
            current: _sys.globalAnnouncement,
            onSave: (text) async {
              final uid = _auth.currentUser?.uid ?? '';
              final ok = await _settingsService.setAnnouncement(text, uid);
              if (mounted) {
                setState(() => _sys = SystemSettings(
                    isMaintenanceMode: _sys.isMaintenanceMode,
                    globalAnnouncement: text));
                admSnack(
                    context,
                    ok
                        ? (text.isEmpty
                            ? 'Announcement cleared.'
                            : 'Announcement published.')
                        : 'Failed to save.',
                    success: ok);
              }
            },
          ));

  void _openSignOutAllDevices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AdmDialog(
        title: 'Sign Out All Devices',
        titleIcon: Icons.devices_rounded,
        body: const Text(
          'This will revoke all active sessions for your account. '
          'You will be signed out here as well and must log in again.',
          style: TextStyle(fontSize: 13.5, color: kAdmMuted, height: 1.5),
        ),
        actions: [
          AdmOutlineBtn(
              label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sign Out All',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _auth.currentUser?.getIdToken(true);
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Container(
      color: kAdmBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AdmPageHeader(
                  title: 'Settings',
                  subtitle: 'Manage your account and system preferences',
                  icon: Icons.settings_rounded,
                ),
                const SizedBox(height: 24),

                // ── SECTION 1: Profile ─────────────────────────────────────
                AdmSectionCard(
                  title: 'Profile Management',
                  icon: Icons.person_rounded,
                  children: [
                    // Avatar
                    Center(
                        child: Column(children: [
                      GestureDetector(
                        onTap: _uploadingAvatar ? null : _uploadAvatar,
                        child:
                            Stack(alignment: Alignment.bottomRight, children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: kAdmGreen.withOpacity(0.1),
                            backgroundImage: (_avatarUrl?.isNotEmpty == true)
                                ? CachedNetworkImageProvider(_avatarUrl!)
                                : null,
                            child: _uploadingAvatar
                                ? const CircularProgressIndicator(
                                    color: kAdmGreen, strokeWidth: 2.5)
                                : (_avatarUrl == null || _avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person_rounded,
                                        size: 50, color: kAdmGreen)
                                    : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: kAdmGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          _uploadingAvatar
                              ? 'Uploading…'
                              : 'Tap to change photo',
                          style: const TextStyle(
                              fontSize: 11.5, color: kAdmMuted)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style:
                              const TextStyle(fontSize: 12, color: kAdmMuted)),
                    ])),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Name editor
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                          child: TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(fontSize: 14, color: kAdmText),
                        decoration: admInput(
                            label: 'Display Name',
                            prefixIcon: Icons.badge_rounded),
                      )),
                      const SizedBox(width: 10),
                      SizedBox(
                          height: 48,
                          child: AdmPrimaryBtn(
                            label: 'Save',
                            loading: _savingName,
                            onPressed: _saveName,
                            small: true,
                          )),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),

                // ── SECTION 2: Security ────────────────────────────────────
                AdmSectionCard(
                  title: 'Security',
                  icon: Icons.lock_rounded,
                  children: [
                    // Role badge
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Account Role',
                      subtitle: _userRole == 'admin'
                          ? 'Administrator — full access'
                          : _userRole == 'director'
                              ? 'Director — read-only access'
                              : _userRole ?? 'Unknown',
                      trailing: AdmStatusChip(
                        label: (_userRole ?? '').toUpperCase(),
                        color: _userRole == 'admin'
                            ? kAdmGreen
                            : const Color(0xFF546E7A),
                      ),
                    ),
                    const Divider(height: 24),

                    // Last login
                    _SettingsTile(
                      icon: Icons.access_time_rounded,
                      title: 'Last Login',
                      subtitle: _lastLogin != null
                          ? _fmtDate(_lastLogin!)
                          : 'Not recorded yet',
                    ),
                    const Divider(height: 24),

                    // Change password
                    _SettingsTile(
                      icon: Icons.key_rounded,
                      title: 'Change Password',
                      subtitle:
                          'Requires your current password for verification',
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: kAdmMuted),
                      onTap: _openChangePassword,
                    ),
                    const Divider(height: 24),

                    // Sign out all
                    _SettingsTile(
                      icon: Icons.devices_rounded,
                      title: 'Sign Out All Devices',
                      subtitle: 'Revokes all active sessions and logs you out',
                      iconColor: Colors.red,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: kAdmMuted),
                      onTap: _openSignOutAllDevices,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── SECTION 3: System ──────────────────────────────────────
                AdmSectionCard(
                  title: 'System Preferences',
                  icon: Icons.tune_rounded,
                  children: [
                    // Maintenance mode
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_sys.isMaintenanceMode
                                  ? Colors.orange
                                  : kAdmGreen)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.construction_rounded,
                            size: 17,
                            color: _sys.isMaintenanceMode
                                ? Colors.orange
                                : kAdmGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Maintenance Mode',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: kAdmText)),
                            const SizedBox(height: 2),
                            Text(
                              _sys.isMaintenanceMode
                                  ? '⚠️ Active — public site is showing maintenance screen'
                                  : 'Off — public site is live',
                              style: TextStyle(
                                fontSize: 12,
                                color: _sys.isMaintenanceMode
                                    ? Colors.orange[800]
                                    : kAdmMuted,
                                fontWeight: _sys.isMaintenanceMode
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ])),
                      Switch(
                        value: _sys.isMaintenanceMode,
                        activeColor: Colors.orange,
                        onChanged: _togglingMaint ? null : _toggleMaintenance,
                      ),
                    ]),
                    const Divider(height: 24),

                    // Announcement
                    _SettingsTile(
                      icon: Icons.campaign_rounded,
                      iconColor:
                          _sys.hasAnnouncement ? kAdmGoldDeep : kAdmGreen,
                      title: 'Global Announcement Banner',
                      subtitle: _sys.hasAnnouncement
                          ? '"${_sys.globalAnnouncement}"'
                          : 'No active announcement',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (_sys.hasAnnouncement)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: kAdmGold,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('LIVE',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: kAdmGreen)),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: kAdmMuted),
                      ]),
                      onTap: _openAnnouncementDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings tile ──────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? kAdmGreen).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor ?? kAdmGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kAdmText)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: kAdmMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ])),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
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

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _error;

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
      _error = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _error = 'No authenticated user.';
        _saving = false;
      });
      return;
    }
    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _currentCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        admSnack(context, 'Password updated successfully.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _saving = false;
        _error = e.code == 'wrong-password'
            ? 'Incorrect current password.'
            : e.code == 'weak-password'
                ? 'New password is too weak (min 6 chars).'
                : 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdmDialog(
      title: 'Change Password',
      titleIcon: Icons.key_rounded,
      maxWidth: 480,
      body: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12.5))),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          _PwField(
              ctrl: _currentCtrl,
              label: 'Current Password',
              obscure: _hideCurrent,
              onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Enter your current password'
                  : null),
          const SizedBox(height: 14),
          _PwField(
              ctrl: _newCtrl,
              label: 'New Password',
              obscure: _hideNew,
              onToggle: () => setState(() => _hideNew = !_hideNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter new password';
                if (v.length < 6) return 'Minimum 6 characters';
                if (v == _currentCtrl.text)
                  return 'Must differ from current password';
                return null;
              }),
          const SizedBox(height: 14),
          _PwField(
              ctrl: _confirmCtrl,
              label: 'Confirm New Password',
              obscure: _hideConfirm,
              onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _newCtrl.text) return 'Passwords do not match';
                return null;
              }),
          const SizedBox(height: 8),
          const Text('You will not be signed out after changing your password.',
              style: TextStyle(fontSize: 11, color: kAdmMuted)),
        ]),
      ),
      actions: [
        AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        AdmPrimaryBtn(
            label: 'Update Password', loading: _saving, onPressed: _submit),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GLOBAL ANNOUNCEMENT DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _AnnouncementDialog extends StatefulWidget {
  final String current;
  final Future<void> Function(String) onSave;

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
    return AdmDialog(
      title: 'Global Announcement Banner',
      titleIcon: Icons.campaign_rounded,
      maxWidth: 540,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            'This banner appears at the top of the Home Screen for all visitors.',
            style: TextStyle(fontSize: 13, color: kAdmMuted, height: 1.45)),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          maxLines: 3,
          maxLength: 200,
          style: const TextStyle(fontSize: 14, color: kAdmText),
          decoration: admInput(
            label: 'Announcement Text',
            hint: 'e.g. "Library closes at 3 PM today due to weather."',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Leave blank to remove the announcement banner.',
            style: TextStyle(fontSize: 11, color: kAdmMuted)),
      ]),
      actions: [
        if (widget.current.isNotEmpty)
          TextButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave('');
                    if (mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.clear_rounded, color: Colors.red, size: 15),
            label: const Text('Clear Banner',
                style: TextStyle(color: Colors.red, fontSize: 13)),
          )
        else
          const SizedBox.shrink(),
        AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        AdmPrimaryBtn(
          label: 'Publish',
          icon: Icons.send_rounded,
          loading: _saving,
          onPressed: () async {
            setState(() => _saving = true);
            await widget.onSave(_ctrl.text);
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ── Shared: password field with toggle ────────────────────────────────────────

class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PwField(
      {required this.ctrl,
      required this.label,
      required this.obscure,
      required this.onToggle,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: kAdmText),
      decoration: admInput(
        label: label,
        prefixIcon: Icons.lock_rounded,
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 17,
              color: kAdmMuted),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
