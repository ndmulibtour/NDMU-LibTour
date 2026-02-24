import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildMainContent(context),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: const Column(
        children: [
          Text(
            'About the Library',
            style: TextStyle(
                color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Providing Learning and Instruction Services to NDMU Community since 1954',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final service = ContentService();

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: MaxWidthContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mission & History ─────────────────────────────────────
            StreamBuilder<AboutData>(
              stream: service.getAboutData(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildSectionSkeleton('Mission & Vision');
                }
                final data = snap.data ?? AboutData.empty();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Vision'),
                    const SizedBox(height: 16),
                    data.visionJson.isEmpty
                        ? _emptyPlaceholder('Vision statement not yet added.')
                        : _QuillViewer(delta: data.visionDelta),
                    const SizedBox(height: 40),
                    _sectionHeader('Mission'),
                    const SizedBox(height: 16),
                    data.missionJson.isEmpty
                        ? _emptyPlaceholder('Mission statement not yet added.')
                        : _QuillViewer(delta: data.missionDelta),
                    const SizedBox(height: 40),
                    _sectionHeader('Historical Background'),
                    const SizedBox(height: 16),
                    data.historyJson.isEmpty
                        ? _emptyPlaceholder(
                            'Historical background not yet added.')
                        : _QuillViewer(delta: data.historyDelta),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // ── Library Personnel ─────────────────────────────────────────
            const Text(
              'Library Personnel',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20)),
            ),
            const Divider(
                color: Color(0xFFFFD700), thickness: 2, endIndent: 100),
            const SizedBox(height: 24),

            StreamBuilder<List<StaffMember>>(
              stream: service.getStaff(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ));
                }
                final staff = snap.data ?? [];
                if (staff.isEmpty) {
                  return _emptyPlaceholder(
                      'Personnel directory not yet added.');
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth <= 700;
                    final crossAxisCount = isMobile ? 2 : 4;

                    // ✅ FIX: Use a taller aspect ratio on mobile so names
                    // and positions are never clipped. Desktop keeps the
                    // original compact ratio.
                    final aspectRatio = isMobile ? 0.72 : 0.85;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: staff.length,
                      itemBuilder: (context, index) =>
                          _StaffCard(member: staff[index]),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20))),
        const Divider(color: Color(0xFFFFD700), thickness: 2, endIndent: 100),
      ],
    );
  }

  Widget _buildSectionSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title),
        const SizedBox(height: 16),
        const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
      ],
    );
  }

  Widget _emptyPlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(message,
            style: TextStyle(color: Colors.grey[500], fontSize: 15)),
      ),
    );
  }
}

// ─── Quill read-only viewer ────────────────────────────────────────────────────

class _QuillViewer extends StatefulWidget {
  final List<dynamic> delta;
  const _QuillViewer({required this.delta});

  @override
  State<_QuillViewer> createState() => _QuillViewerState();
}

class _QuillViewerState extends State<_QuillViewer> {
  late QuillController _ctrl;
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = _buildCtrl(widget.delta);
  }

  QuillController _buildCtrl(List<dynamic> delta) {
    try {
      return QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      return QuillController.basic()..readOnly = true;
    }
  }

  @override
  void didUpdateWidget(_QuillViewer old) {
    super.didUpdateWidget(old);
    if (old.delta != widget.delta) {
      _ctrl.dispose();
      _ctrl = _buildCtrl(widget.delta);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      controller: _ctrl,
      scrollController: _scroll,
      focusNode: _focus,
      config: QuillEditorConfig(
        scrollable: false,
        autoFocus: false,
        expands: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 6),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
}

// ─── Staff Card ────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ FIX: Scale avatar radius based on available card width so it
        // never crowds out the name/position text on narrow mobile cards.
        final avatarRadius = (constraints.maxWidth * 0.28).clamp(32.0, 55.0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: const Color(0xFF1B5E20).withOpacity(0.1), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
                  backgroundImage:
                      (member.imageUrl != null && member.imageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(member.imageUrl!)
                          : null,
                  child: (member.imageUrl == null || member.imageUrl!.isEmpty)
                      ? Icon(Icons.person,
                          size: avatarRadius * 0.8,
                          color: const Color(0xFF1B5E20))
                      : null,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 2,
                  width: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                // ✅ FIX: Name uses flexible text sizing and allows wrapping
                // so long names (e.g. "Myra T. Morta") display fully.
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ FIX: Position allows up to 3 lines so long titles
                // like "Director, Libraries & EMC" are never clipped.
                Text(
                  member.position,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          constraints: const BoxConstraints(maxWidth: 1000), child: child));
}
