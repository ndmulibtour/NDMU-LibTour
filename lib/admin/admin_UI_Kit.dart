// lib/admin/admin_ui_kit.dart
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NDMU LibTour — Shared Admin Design System  (updated)
// Glassmorphism + NDMU green/gold theme. Used by every admin screen.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// NEW in this revision
//   • AdmScaffold   — consistent page-level chrome (bg, scroll, padding)
//   • AdmPageHeader — updated: no scaffold / appBar needed in screens
//   • All existing components preserved as-is

import 'dart:ui';
import 'package:flutter/material.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const kAdmGreen = Color(0xFF1B5E20);
const kAdmGreenMid = Color(0xFF2E7D32);
const kAdmGreenDark = Color(0xFF0D3F0F);
const kAdmGold = Color(0xFFFFD700);
const kAdmGoldDeep = Color(0xFFF9A825);
const kAdmBg = Color(0xFFF0F4EF);
const kAdmText = Color(0xFF1A2E1A);
const kAdmMuted = Color(0xFF6B7E6B);

// Status palette (shared by all screens)
const kStatusPending = Color(0xFFE65100);
const kStatusReviewed = Color(0xFF2E7D32);
const kStatusResolved = Color(0xFF0277BD);
const kStatusNew = Color(0xFFE65100);
const kStatusRead = Color(0xFF6A1B9A);
const kStatusResponded = Color(0xFF2E7D32);

// Responsive breakpoints
const double kBpMobile = 600.0;
const double kBpTablet = 900.0;

// ═════════════════════════════════════════════════════════════════════════════
// ADM SCAFFOLD
// Drop-in page wrapper. Replaces Scaffold + appBar in every screen.
// Provides consistent bg color, scroll container, and padding.
// ═════════════════════════════════════════════════════════════════════════════
class AdmScaffold extends StatelessWidget {
  /// The column content (header + body). Will be wrapped in a scroll view.
  final Widget child;

  /// Pass `false` if the content should NOT be scrollable (e.g. contains its
  /// own Expanded list). Defaults to `true`.
  final bool scrollable;

  const AdmScaffold({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      color: kAdmBg,
      width: double.infinity,
      child: child,
    );

    if (!scrollable) return inner;

    return Container(
      color: kAdmBg,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ═════════════════════════════════════════════════════════════════════════════
class AdmGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool subtle;

  const AdmGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 16,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: subtle
                ? Colors.white.withOpacity(0.72)
                : Colors.white.withOpacity(0.91),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(subtle ? 0.55 : 0.80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.048),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAGE HEADER  — title + subtitle + optional action buttons
// Used at the top of every admin screen (no AppBar needed).
// ═════════════════════════════════════════════════════════════════════════════
class AdmPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final List<Widget> actions;

  const AdmPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < kBpMobile;
    final c = accentColor ?? kAdmGreen;

    final iconBox = Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.bold, color: kAdmText)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 12.5, color: kAdmMuted)),
      ],
    );

    if (mobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(child: texts),
        ]),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ]);
    }

    return Row(children: [
      iconBox,
      const SizedBox(width: 14),
      Expanded(child: texts),
      ...actions,
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION LABEL  — gold-bar + icon + text heading within a card
// ═════════════════════════════════════════════════════════════════════════════
class AdmSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;

  const AdmSectionLabel({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kAdmGold, kAdmGoldDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      if (icon != null) ...[
        Icon(icon, size: 14, color: kAdmGreen),
        const SizedBox(width: 5),
      ],
      Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: kAdmText,
          letterSpacing: -0.1,
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIMARY BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class AdmPrimaryBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool small;

  const AdmPrimaryBtn({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kAdmGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kAdmGreen.withOpacity(0.45),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 16 : 22,
          vertical: small ? 10 : 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: loading
          ? SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.8),
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: small ? 15 : 16),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: small ? 12.5 : 13.5,
                  ),
                ),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// OUTLINE BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class AdmOutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const AdmOutlineBtn({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kAdmGreen;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15),
            const SizedBox(width: 6),
          ],
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATUS CHIP
// ═════════════════════════════════════════════════════════════════════════════
class AdmStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AdmStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═════════════════════════════════════════════════════════════════════════════
class AdmSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;

  const AdmSearchBar(
      {super.key, required this.onChanged, this.hint = 'Search…'});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13.5, color: kAdmText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: kAdmMuted.withOpacity(0.7), fontSize: 13),
            prefixIcon:
                const Icon(Icons.search_rounded, color: kAdmGreen, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.82),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kAdmGreen.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAdmGreen, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTER CHIPS
// ═════════════════════════════════════════════════════════════════════════════
class AdmFilterChips extends StatelessWidget {
  final List<String> options;
  final Map<String, String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  const AdmFilterChips({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final sel = opt == selected;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? kAdmGreen : Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? kAdmGreen : kAdmGreen.withOpacity(0.2),
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: kAdmGreen.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Text(
              labels[opt] ?? opt,
              style: TextStyle(
                color: sel ? Colors.white : kAdmMuted,
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STAT MINI-CARD  — icon + number + label
// ═════════════════════════════════════════════════════════════════════════════
class AdmStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AdmStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdmGlass(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: const TextStyle(fontSize: 11, color: kAdmMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION CARD  — glassmorphism card with green gradient header
// ═════════════════════════════════════════════════════════════════════════════
class AdmSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const AdmSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AdmGlass(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kAdmGreen.withOpacity(0.07),
                kAdmGreenMid.withOpacity(0.02)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border:
                Border(bottom: BorderSide(color: kAdmGreen.withOpacity(0.1))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kAdmGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: kAdmGreen),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kAdmText)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG  — glassmorphism dialog with green header bar
// ═════════════════════════════════════════════════════════════════════════════
class AdmDialog extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  const AdmDialog({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.body,
    required this.actions,
    this.maxWidth = 580,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: maxWidth,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.82), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── Green header bar ──────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAdmGreen, kAdmGreenMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Icon(titleIcon, color: kAdmGold, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ]),
              ),

              // ── Scrollable body ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: body,
                ),
              ),

              // ── Footer actions ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: kAdmBg.withOpacity(0.5),
                  border: Border(
                      top: BorderSide(color: kAdmGreen.withOpacity(0.08))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .expand((w) => [w, const SizedBox(width: 10)])
                      .toList()
                    ..removeLast(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DELETE CONFIRM DIALOG
// ═════════════════════════════════════════════════════════════════════════════
Future<bool> admConfirmDelete(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 390,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: kAdmText),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(fontSize: 13, color: kAdmMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AdmOutlineBtn(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context, false)),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    ),
  );
  return result ?? false;
}

// ═════════════════════════════════════════════════════════════════════════════
// SNACK BAR HELPER
// ═════════════════════════════════════════════════════════════════════════════
void admSnack(BuildContext context, String msg, {bool success = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(
        success ? Icons.check_circle_outline : Icons.error_outline,
        color: Colors.white,
        size: 18,
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 13.5))),
    ]),
    backgroundColor: success ? kAdmGreen : Colors.red[700],
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ));
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════
class AdmEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const AdmEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kAdmGreen.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 46, color: kAdmGreen.withOpacity(0.32)),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 15.5, fontWeight: FontWeight.bold, color: kAdmText)),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(fontSize: 13, color: kAdmMuted),
            textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═════════════════════════════════════════════════════════════════════════════
class AdmLoading extends StatelessWidget {
  final String? message;
  const AdmLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: kAdmGreen, strokeWidth: 2.5),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(message!,
              style: const TextStyle(color: kAdmMuted, fontSize: 13)),
        ],
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFO ROW  — for detail dialogs
// ═════════════════════════════════════════════════════════════════════════════
class AdmInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const AdmInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: kAdmGreen),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12.5, color: kAdmMuted),
          ),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12.5, color: kAdmText)),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED INPUT DECORATION
// ═════════════════════════════════════════════════════════════════════════════
InputDecoration admInput({
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: kAdmGreen, size: 18)
        : null,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: kAdmMuted, fontSize: 13.5),
    hintStyle: TextStyle(color: kAdmMuted.withOpacity(0.6), fontSize: 13),
    filled: true,
    fillColor: Colors.white.withOpacity(0.75),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kAdmGreen.withOpacity(0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kAdmGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// TILE ACTION BUTTON  — used in list tiles
// ═════════════════════════════════════════════════════════════════════════════
class AdmTileBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const AdmTileBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<AdmTileBtn> createState() => _AdmTileBtnState();
}

class _AdmTileBtnState extends State<AdmTileBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _h
                  ? widget.color.withOpacity(0.85)
                  : widget.color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.color.withOpacity(_h ? 0.0 : 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _h ? Colors.white : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOVERABLE GLASS LIST TILE CONTAINER
// ═════════════════════════════════════════════════════════════════════════════
class AdmHoverTile extends StatefulWidget {
  final Widget child;
  final EdgeInsets? margin;

  const AdmHoverTile({super.key, required this.child, this.margin});

  @override
  State<AdmHoverTile> createState() => _AdmHoverTileState();
}

class _AdmHoverTileState extends State<AdmHoverTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: widget.margin ?? const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _h
              ? Colors.white.withOpacity(0.97)
              : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _h
                ? kAdmGreen.withOpacity(0.26)
                : Colors.white.withOpacity(0.78),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _h
                  ? kAdmGreen.withOpacity(0.07)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _h ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RICH TEXT EDITOR CONTAINER  — consistent border/bg for QuillEditor usage
// ═════════════════════════════════════════════════════════════════════════════
class AdmRichTextContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const AdmRichTextContainer({
    super.key,
    required this.child,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAdmGreen.withOpacity(0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
