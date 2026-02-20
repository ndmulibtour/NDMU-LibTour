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
            'Excellence in Information Service since 1954',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 18),
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
                    _sectionHeader('Mission & Vision'),
                    const SizedBox(height: 16),
                    data.missionJson.isEmpty
                        ? _emptyPlaceholder(
                            'Mission & Vision content not yet added.')
                        // ✅ FIX: _QuillViewer is a StatefulWidget that owns
                        //         and disposes its controllers in initState/dispose
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

            // ── Library Staff ─────────────────────────────────────────
            const Text(
              'Library Staff',
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
                  return _emptyPlaceholder('Staff directory not yet added.');
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85,
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
//
// ✅ FIX 3 — Memory leak resolved:
//   Previous code passed ScrollController() and FocusNode() directly into
//   QuillEditor inside the build() method — every rebuild created new objects
//   that were never disposed.
//
//   Solution: _QuillViewer is a StatefulWidget. The QuillController,
//   ScrollController, and FocusNode are all created in initState() and freed
//   in dispose(). The build() method reads from fields — no allocations.

class _QuillViewer extends StatefulWidget {
  final List<dynamic> delta;
  const _QuillViewer({required this.delta});

  @override
  State<_QuillViewer> createState() => _QuillViewerState();
}

class _QuillViewerState extends State<_QuillViewer> {
  late QuillController _ctrl;
  // ✅ Declared as fields — created once, freed once
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
    // Only rebuild if the delta actually changed (e.g. admin saved new content)
    if (old.delta != widget.delta) {
      _ctrl.dispose();
      _ctrl = _buildCtrl(widget.delta);
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
    // ✅ No allocations here — only reads from fields
    return QuillEditor(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
              backgroundImage:
                  (member.imageUrl != null && member.imageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(member.imageUrl!)
                      : null,
              child: (member.imageUrl == null || member.imageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 44, color: Color(0xFF1B5E20))
                  : null,
            ),
            const SizedBox(height: 14),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 4),
            Text(
              member.position,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
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
          constraints: const BoxConstraints(maxWidth: 1000), child: child));
}
