import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isMobile),
            _buildDynamicContent(isMobile),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Library Policies',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rules and Guidelines for Library Use',
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: isMobile ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent(bool isMobile) {
    return StreamBuilder<List<PolicyItem>>(
      stream: ContentService().getPolicies(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
                child: Text('Unable to load policies: ${snap.error}',
                    style: const TextStyle(color: Colors.red))),
          );
        }

        final items = snap.data ?? [];

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Text(
                'No policies have been added yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: MaxWidthContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index < items.length - 1 ? 20 : 40),
                    // ✅ FIX — _DynamicPolicyCard is a StatefulWidget that
                    //          owns and disposes its own QuillController,
                    //          ScrollController, and FocusNode in
                    //          initState/dispose. The build() method allocates
                    //          nothing disposable.
                    child: _DynamicPolicyCard(item: item, isMobile: isMobile),
                  );
                }),
                _buildImportantNotice(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportantNotice(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF3CD).withOpacity(0.9),
                const Color(0xFFFFE082).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Violation of library policies may result in '
                      'suspension of library privileges. '
                      'For complete policy details, please contact '
                      'the library administration.',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFF5D4037),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dynamic Policy Card ──────────────────────────────────────────────────────
//
// ✅ FIX — Memory leak resolved:
//   The previous build() method passed ScrollController() and FocusNode()
//   directly to QuillEditor, creating new objects on every rebuild with no
//   way to dispose them.
//
//   Solution: _DynamicPolicyCard is a StatefulWidget. The QuillController,
//   ScrollController, and FocusNode are fields created in initState() and
//   freed in dispose(). The build() method reads from fields — zero allocations.

class _DynamicPolicyCard extends StatefulWidget {
  final PolicyItem item;
  final bool isMobile;

  const _DynamicPolicyCard({required this.item, required this.isMobile});

  @override
  State<_DynamicPolicyCard> createState() => _DynamicPolicyCardState();
}

class _DynamicPolicyCardState extends State<_DynamicPolicyCard> {
  late QuillController _ctrl;
  // ✅ Declared as fields — created once, freed once
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = _buildController();
  }

  QuillController _buildController() {
    try {
      return QuillController(
        document: Document.fromJson(widget.item.deltaJson),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      return QuillController(
        document: Document()..insert(0, widget.item.plainText),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  @override
  void didUpdateWidget(_DynamicPolicyCard old) {
    super.didUpdateWidget(old);
    if (old.item.id != widget.item.id ||
        old.item.contentJson != widget.item.contentJson) {
      _ctrl.dispose();
      _ctrl = _buildController();
    }
  }

  @override
  void dispose() {
    // ✅ All three objects freed in dispose — no memory leak
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    final item = widget.item;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1B5E20).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(item.icon,
                        color: const Color(0xFFFFD700), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Gold accent bar
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ QuillEditor reads from field controllers — no allocation
              QuillEditor(
                controller: _ctrl,
                scrollController: _scroll,
                focusNode: _focus,
                // ✅ flutter_quill v11 API: config: (not configurations:)
                config: QuillEditorConfig(
                  scrollable: false,
                  autoFocus: false,
                  expands: false,
                  padding: EdgeInsets.zero,
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 6),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MaxWidthContainer ────────────────────────────────────────────────────────

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  const MaxWidthContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      );
}
