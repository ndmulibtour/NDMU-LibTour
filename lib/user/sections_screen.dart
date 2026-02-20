import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ndmu_libtour/admin/models/section_model.dart';
import 'package:ndmu_libtour/admin/services/section_service.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import '../utils/responsive_helper.dart';

class LibrarySectionsScreen extends StatefulWidget {
  const LibrarySectionsScreen({super.key});

  @override
  State<LibrarySectionsScreen> createState() => _LibrarySectionsScreenState();
}

class _LibrarySectionsScreenState extends State<LibrarySectionsScreen> {
  final SectionService _sectionService = SectionService();

  // ── CRITICAL: cache the stream so setState() never creates a new one.
  // When stream: receives a new Stream object, StreamBuilder resets to
  // ConnectionState.waiting and shows the loading spinner — that IS the flicker.
  // Storing it here means the same Firestore listener is reused across rebuilds.
  late final Stream<List<LibrarySection>> _sectionsStream =
      _sectionService.getSections();

  // ── Selection ─────────────────────────────────────────────────────────────
  String? _selectedId;

  // ── Scroll controller for the right-panel — reset on section change ───────
  final ScrollController _contentScroll = ScrollController();

  // ── QuillController cache ─────────────────────────────────────────────────
  // Building a QuillController inside build() is expensive and causes a flash.
  // We cache one per section ID and reuse it every rebuild.
  final Map<String, QuillController> _controllers = {};

  @override
  void dispose() {
    _contentScroll.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  QuillController _controllerFor(LibrarySection section) {
    if (_controllers.containsKey(section.id)) return _controllers[section.id]!;
    QuillController ctrl;
    try {
      ctrl = section.description.isNotEmpty
          ? QuillController(
              document: Document.fromJson(section.descriptionJson),
              selection: const TextSelection.collapsed(offset: 0),
              readOnly: true,
            )
          : (QuillController.basic()..readOnly = true);
    } catch (_) {
      ctrl = QuillController.basic()..readOnly = true;
    }
    _controllers[section.id] = ctrl;
    return ctrl;
  }

  void _evictStale(List<LibrarySection> sections) {
    final live = {for (final s in sections) s.id};
    final dead = _controllers.keys.where((k) => !live.contains(k)).toList();
    for (final k in dead) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  void _select(String id) {
    if (_selectedId == id) return;
    setState(() => _selectedId = id);
    // Scroll the content panel back to the top without recreating it.
    if (_contentScroll.hasClients) {
      _contentScroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: StreamBuilder<List<LibrarySection>>(
        // Uses the cached stream — never recreated on rebuild.
        stream: _sectionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            // Only show loading on the very first load, not on every setState.
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error loading sections',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final sections = snapshot.data ?? [];
          if (sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No sections available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          // Initialise selection only when truly needed — NOT on every emission.
          if (_selectedId == null ||
              !sections.any((s) => s.id == _selectedId)) {
            _selectedId = sections.first.id;
          }

          _evictStale(sections);

          return isMobile
              ? _buildMobileLayout(sections)
              : _buildDesktopLayout(sections);
        },
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(List<LibrarySection> sections) {
    final selected = sections.firstWhere(
      (s) => s.id == _selectedId,
      orElse: () => sections.first,
    );

    return Row(
      children: [
        // ── Left Sidebar ─────────────────────────────────────────────────
        // Sidebar is a stable widget — it does NOT get a key that changes,
        // so Flutter reuses the same element and only re-renders the items
        // whose isSelected flag changed.
        Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF0D3F0F)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(2, 0))
            ],
          ),
          child: Column(
            children: [
              // Header — constant, never rebuilds
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Library Sections',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Select a section to view details',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final s = sections[index];
                    return _SidebarItem(
                      key: ValueKey(s.id),
                      section: s,
                      isSelected: _selectedId == s.id,
                      onTap: () => _select(s.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Right content panel ──────────────────────────────────────────
        // SingleChildScrollView has NO key tied to _selectedId.
        // Changing selection does NOT destroy this scroll view — only the
        // AnimatedSwitcher child inside it crossfades.
        Expanded(
          child: SingleChildScrollView(
            controller: _contentScroll,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: _SectionDetailPanel(
                      // ValueKey drives AnimatedSwitcher to swap children.
                      key: ValueKey(selected.id),
                      section: selected,
                      isMobile: false,
                      controller: _controllerFor(selected),
                      onTourTap: () => _onTourTap(selected),
                    ),
                  ),
                ),
                const BottomBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(List<LibrarySection> sections) {
    final selected = sections.firstWhere(
      (s) => s.id == _selectedId,
      orElse: () => sections.first,
    );

    return SingleChildScrollView(
      // No key — this scroll view is always the same widget instance.
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Text('Library Sections',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center),
          ),
          _buildMobileSectionsGrid(sections),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _SectionDetailPanel(
                key: ValueKey(selected.id),
                section: selected,
                isMobile: true,
                controller: _controllerFor(selected),
                onTourTap: () => _onTourTap(selected),
              ),
            ),
          ),
          const BottomBar(),
        ],
      ),
    );
  }

  Widget _buildMobileSectionsGrid(List<LibrarySection> sections) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final s = sections[index];
          return _MobileCard(
            key: ValueKey(s.id),
            section: s,
            isSelected: _selectedId == s.id,
            onTap: () => _select(s.id),
          );
        },
      ),
    );
  }

  void _onTourTap(LibrarySection section) {
    final hasScene = section.sceneId != null && section.sceneId!.isNotEmpty;
    if (hasScene) {
      Navigator.pushNamed(context, '/virtual-tour', arguments: {
        'source': 'sections',
        'sceneId': section.sceneId,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.vrpano, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Virtual tour not available for "${section.name}" yet.')),
        ]),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _SidebarItem — extracted widget so it has its own element/state.
// Flutter's element reuse means only the TWO items whose selection changed
// rebuild; all others are completely skipped.
// ═══════════════════════════════════════════════════════════════════════════
class _SidebarItem extends StatelessWidget {
  final LibrarySection section;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    super.key,
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (section.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            section.imageUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.library_books,
                                color: Colors.white,
                                size: 36),
                          ),
                        )
                      else
                        const Icon(Icons.library_books,
                            color: Colors.white, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.9),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(section.floor,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : Colors.white54,
                          size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _MobileCard — extracted so AnimatedContainer only affects this widget,
// not the entire grid.
// ═══════════════════════════════════════════════════════════════════════════
class _MobileCard extends StatelessWidget {
  final LibrarySection section;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileCard({
    super.key,
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        const Color(0xFF1B5E20).withOpacity(0.15),
                        Colors.white.withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700).withOpacity(0.6)
                    : const Color(0xFF1B5E20).withOpacity(0.15),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF1B5E20).withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 12 : 8,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (section.imageUrl != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)])
                          : LinearGradient(colors: [
                              const Color(0xFF1B5E20).withOpacity(0.1),
                              const Color(0xFF1B5E20).withOpacity(0.05),
                            ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        section.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.library_books,
                            size: 32,
                            color: Color(0xFF1B5E20)),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)])
                          : LinearGradient(colors: [
                              const Color(0xFF1B5E20).withOpacity(0.1),
                              const Color(0xFF1B5E20).withOpacity(0.05),
                            ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.library_books,
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF1B5E20),
                        size: 32),
                  ),
                const SizedBox(height: 12),
                Text(
                  section.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFD700).withOpacity(0.2)
                        : const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.floor,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFF1B5E20) : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _SectionDetailPanel — extracted so AnimatedSwitcher can swap ONLY this
// widget. Being a separate class means Flutter creates/destroys it cleanly
// during the crossfade without touching any parent scroll state.
// ═══════════════════════════════════════════════════════════════════════════
class _SectionDetailPanel extends StatelessWidget {
  final LibrarySection section;
  final bool isMobile;
  final QuillController controller;
  final VoidCallback onTourTap;

  const _SectionDetailPanel({
    super.key,
    required this.section,
    required this.isMobile,
    required this.controller,
    required this.onTourTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasScene = section.sceneId != null && section.sceneId!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable hero image ────────────────────────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTourTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    height: isMobile ? 250 : 400,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF1B5E20).withOpacity(0.2),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF1B5E20).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: section.imageUrl != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                section.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(hasScene),
                              ),
                              _buildOverlayBadge(hasScene, isMobile, context),
                            ],
                          )
                        : _buildPlaceholder(hasScene),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Info card ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
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
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF1B5E20).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: section.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    section.imageUrl!,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.library_books,
                                        color: Color(0xFFFFD700),
                                        size: 28),
                                  ),
                                )
                              : const Icon(Icons.library_books,
                                  color: Color(0xFFFFD700), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.name,
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFFD700)
                                          .withOpacity(0.4),
                                      width: 1),
                                ),
                                child: Text('Floor ${section.floor}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFC107)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDescription(isMobile, context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isMobile, BuildContext context) {
    if (section.description.isEmpty) {
      return Text(
        'No description available.',
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          color: Colors.grey[600],
          height: 1.6,
        ),
      );
    }
    // Uses the controller passed in from the cache — no recreation, no flash.
    return QuillEditor.basic(
      controller: controller,
      config: const QuillEditorConfig(padding: EdgeInsets.zero),
    );
  }

  Widget _buildOverlayBadge(
      bool hasScene, bool isMobile, BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasScene
                  ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                  : [Colors.black54, Colors.black38],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (hasScene ? const Color(0xFF1B5E20) : Colors.black)
                    .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasScene ? Icons.vrpano : Icons.vrpano_outlined,
                color: hasScene ? const Color(0xFFFFD700) : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                hasScene
                    ? 'Tap to view in virtual tour'
                    : 'Virtual tour not available',
                style: TextStyle(
                  color: hasScene ? Colors.white : Colors.white54,
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool hasScene) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.panorama,
          size: 120,
          color: const Color(0xFF1B5E20).withOpacity(0.3),
        ),
        Positioned(
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasScene
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [Colors.black54, Colors.black38],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: (hasScene ? const Color(0xFF1B5E20) : Colors.black)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasScene ? Icons.vrpano : Icons.vrpano_outlined,
                  color: hasScene ? const Color(0xFFFFD700) : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasScene
                      ? 'Tap to view in virtual tour'
                      : 'Virtual tour not available',
                  style: TextStyle(
                      color: hasScene ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
