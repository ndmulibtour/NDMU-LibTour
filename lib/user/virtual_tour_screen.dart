import 'package:flutter/material.dart';
import 'dart:ui';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;

import 'package:ndmu_libtour/user/models/tour_sections.dart';

// ─────────────────────────────────────────────────────────────────────────────
// One-time global registration guard.
// registerViewFactory() may only be called ONCE per viewType for the entire
// lifetime of the Flutter web app. Subsequent calls are silently ignored —
// the iframe src from the FIRST registration is reused forever.
// Fix: always register with a fixed src, then drive the initial scene via
// postMessage once the iframe signals wrapperReady.
// ─────────────────────────────────────────────────────────────────────────────
bool _viewFactoryRegistered = false;

void _ensureViewFactoryRegistered() {
  if (_viewFactoryRegistered) return;
  _viewFactoryRegistered = true;

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    'panoee-wrapper-view',
    (int viewId) {
      final iframe = html.IFrameElement()
        ..id = 'panoee-wrapper-iframe'
        ..src = '/panoee_tour.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; xr-spatial-tracking'
        ..allowFullscreen = true;

      iframe.onLoad.listen((_) => debugPrint('Wrapper iframe loaded'));
      return iframe;
    },
  );
}

class VirtualTourScreen extends StatefulWidget {
  final String? initialSceneId;

  /// Where the user navigated from. Controls the back-button icon and tooltip.
  /// Passed via Navigator.pushNamed arguments map:
  ///   'home'     → home icon,     "Back to Home"
  ///   'sections' → book icon,     "Back to Sections"
  ///   anything else / null → arrow back, "Go back"
  final String? source;

  const VirtualTourScreen({
    super.key,
    this.initialSceneId,
    this.source,
  });

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _currentLocation = "Outside Library";
  String _currentSceneId = "6978265df7083ba3665904a6";
  bool _isLoading = true;
  int? _expandedFloorIndex;

  bool _wrapperReady = false;
  String? _pendingSceneId;

  final Color ndmuGreen = const Color(0xFF1B5E20);
  final Color ndmuGold = const Color(0xFFFFD700);
  final Color ndmuDarkGreen = const Color(0xFF0D3F0F);

  @override
  void initState() {
    super.initState();
    _ensureViewFactoryRegistered();

    if (widget.initialSceneId != null && widget.initialSceneId!.isNotEmpty) {
      _currentSceneId = widget.initialSceneId!;
      for (final floor in libraryFloors) {
        for (final section in floor.sections) {
          if (section.sceneId == _currentSceneId) {
            _currentLocation = section.title;
            break;
          }
        }
      }
      _pendingSceneId = _currentSceneId;
    }

    _setupMessageListener();
    _updateExpandedFloor();
  }

  // ── Back-button appearance ──────────────────────────────────────────────────

  IconData get _backIcon {
    switch (widget.source) {
      case 'home':
        return Icons.home_rounded;
      case 'sections':
        return Icons.library_books_rounded;
      default:
        return Icons.arrow_back_rounded;
    }
  }

  String get _backTooltip {
    switch (widget.source) {
      case 'home':
        return 'Back to Home';
      case 'sections':
        return 'Back to Sections';
      default:
        return 'Go back';
    }
  }

  // ── Message listener ────────────────────────────────────────────────────────

  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;
      try {
        final type = data['type'] as String?;

        if (type == 'wrapperReady') {
          debugPrint('✅ Wrapper ready');
          _wrapperReady = true;
          if (_pendingSceneId != null) {
            final pending = _pendingSceneId!;
            _pendingSceneId = null;
            _sendRawNavigationMessage(pending, _currentLocation);
          }
        } else if (type == 'tourLoaded') {
          debugPrint('✅ Tour loaded');
          final sceneId = data['scene'] as String?;
          if (sceneId != null && mounted) _updateCurrentScene(sceneId);
          if (mounted) setState(() => _isLoading = false);
        } else if (type == 'navigationStarted') {
          debugPrint('🎯 Navigation started: ${data['scene']}');
          final sceneId = data['scene'] as String?;
          final sceneName = data['name'] as String?;
          if (sceneId != null && mounted) {
            setState(() {
              _currentSceneId = sceneId;
              if (sceneName != null) _currentLocation = sceneName;
              _isLoading = true;
            });
            _updateExpandedFloor();
          }
        }
      } catch (e) {
        debugPrint('Error parsing message: $e');
      }
    });
  }

  void _updateCurrentScene(String sceneId) {
    String? foundName;
    for (final floor in libraryFloors) {
      for (final section in floor.sections) {
        if (section.sceneId == sceneId) {
          foundName = section.title;
          break;
        }
      }
      if (foundName != null) break;
    }
    if (!mounted) return;
    setState(() {
      _currentSceneId = sceneId;
      if (foundName != null) _currentLocation = foundName;
    });
    _updateExpandedFloor();
  }

  void _updateExpandedFloor() {
    for (int i = 0; i < libraryFloors.length; i++) {
      for (final section in libraryFloors[i].sections) {
        if (section.sceneId == _currentSceneId) {
          if (mounted) setState(() => _expandedFloorIndex = i);
          return;
        }
      }
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _navigateToScene(TourSection section) {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState!.closeDrawer();
    }
    if (section.sceneId == _currentSceneId) return;

    debugPrint('🎯 Requesting: ${section.title} (${section.sceneId})');
    setState(() {
      _currentLocation = section.title;
      _currentSceneId = section.sceneId;
      _isLoading = true;
    });
    _updateExpandedFloor();
    _sendRawNavigationMessage(section.sceneId, section.title);
  }

  void _sendRawNavigationMessage(String sceneId, String sceneName) {
    try {
      final iframe = html.document.getElementById('panoee-wrapper-iframe')
          as html.IFrameElement?;
      if (iframe?.contentWindow != null) {
        iframe!.contentWindow!.postMessage({
          'action': 'navigateToScene',
          'sceneId': sceneId,
          'sceneName': sceneName,
        }, '*');
        debugPrint('📤 Navigation message sent: $sceneName');
      } else {
        debugPrint('❌ Wrapper iframe not found or not ready');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error sending navigation message: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleIFrameInteraction(bool interactive) {
    final iframe = html.document.getElementById('panoee-wrapper-iframe');
    if (iframe != null) {
      iframe.style.pointerEvents = interactive ? 'auto' : 'none';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: ndmuGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ndmuGreen, ndmuDarkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
                bottom: BorderSide(color: Color(0xFFFFD700), width: 3)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: ndmuGold, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: ndmuGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Image.asset('assets/images/ndmu_logo.png',
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school,
                      size: 35, color: Color(0xFF1B5E20))),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Virtual Tour",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5)),
                  Text("NDMU Library Navigator",
                      style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ── Context-aware back button ──────────────────────────────────────
          // Icon and tooltip change depending on where the user came from.
          // Navigator.pop() always works since VirtualTourScreen is always pushed.
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: Icon(_backIcon, color: Colors.white),
              tooltip: _backTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
              tooltip: 'Help',
              onPressed: _showHelp,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      onDrawerChanged: (isOpen) => _toggleIFrameInteraction(!isOpen),
      drawer: _buildSidebar(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: HtmlElementView(viewType: 'panoee-wrapper-view'),
          ),
          if (!_isLoading)
            Positioned(
              bottom: 24,
              left: 24,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(30),
                shadowColor: ndmuGreen.withOpacity(0.4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [ndmuGreen, ndmuGreen.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: ndmuGold, shape: BoxShape.circle),
                        child: const Icon(Icons.place,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Current Location",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(_currentLocation,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sidebar ─────────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF5F5F5).withValues(alpha: 0.98),
                  Colors.white.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ndmuGreen, ndmuDarkGreen]),
                    boxShadow: [
                      BoxShadow(
                          color: ndmuGreen.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ndmuGold, width: 2),
                            ),
                            child: Image.asset('assets/images/ndmu_logo.png',
                                height: 36,
                                errorBuilder: (_, __, ___) => Icon(Icons.school,
                                    size: 32, color: ndmuGreen)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Library Navigator",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text("NDMU Virtual Tour",
                                    style: TextStyle(
                                        color: ndmuGold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: ndmuGold.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [ndmuGreen, ndmuDarkGreen]),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.info_outline_rounded,
                                      size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Text("Currently viewing",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  ndmuGreen.withValues(alpha: 0.1),
                                  ndmuGreen.withValues(alpha: 0.05),
                                ]),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: ndmuGold.withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: ndmuGold, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_currentLocation,
                                        style: TextStyle(
                                            color: ndmuGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: libraryFloors.length,
                    itemBuilder: (context, index) =>
                        _buildFloorSection(libraryFloors[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSection(FloorData floor, int floorIndex) {
    final isExpanded = _expandedFloorIndex == floorIndex;
    final hasCurrentScene =
        floor.sections.any((s) => s.sceneId == _currentSceneId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isExpanded
                    ? [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.85)
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.6)
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded
                    ? ndmuGold.withValues(alpha: 0.4)
                    : hasCurrentScene
                        ? ndmuGreen.withValues(alpha: 0.3)
                        : Colors.grey[200]!,
                width: isExpanded ? 2 : (hasCurrentScene ? 2 : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpanded
                      ? ndmuGold.withValues(alpha: 0.2)
                      : hasCurrentScene
                          ? ndmuGreen.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                  blurRadius: isExpanded ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.only(bottom: 12, top: 4),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) => setState(
                    () => _expandedFloorIndex = expanded ? floorIndex : null),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExpanded
                          ? [ndmuGold, const Color(0xFFFFC107)]
                          : hasCurrentScene
                              ? [ndmuGreen, ndmuDarkGreen]
                              : [Colors.grey[300]!, Colors.grey[200]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: (isExpanded || hasCurrentScene)
                        ? [
                            BoxShadow(
                                color: (isExpanded ? ndmuGold : ndmuGreen)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Icon(Icons.layers_rounded,
                      color: (isExpanded || hasCurrentScene)
                          ? (isExpanded ? ndmuGreen : Colors.white)
                          : Colors.grey[600],
                      size: 22),
                ),
                title: Text(floor.floorName,
                    style: TextStyle(
                        color: isExpanded || hasCurrentScene
                            ? ndmuGreen
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${floor.sections.length} section${floor.sections.length > 1 ? 's' : ''}',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                trailing: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? ndmuGold : ndmuGreen,
                  size: 24,
                ),
                children: floor.sections.map((section) {
                  final isCurrent = section.sceneId == _currentSceneId;
                  return InkWell(
                    onTap: () => _navigateToScene(section),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? ndmuGreen.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? ndmuGreen.withOpacity(0.4)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isCurrent ? ndmuGold : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCurrent ? Icons.place : Icons.place_outlined,
                              color:
                                  isCurrent ? Colors.white : Colors.grey[600],
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(section.title,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? ndmuGreen
                                        : Colors.black87)),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  ndmuGold,
                                  ndmuGold.withOpacity(0.8)
                                ]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: ndmuGold.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: const Text('CURRENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                            )
                          else
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Help dialog ─────────────────────────────────────────────────────────────

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [ndmuGreen, ndmuGreen.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_center_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text("Navigation Guide",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(Icons.menu_rounded, "Side Menu",
                  "Open the menu (☰) to see all library sections organized by floor."),
              _buildHelpItem(Icons.touch_app_rounded, "Quick Navigation",
                  "Tap any section name to instantly jump to that location."),
              _buildHelpItem(Icons.threed_rotation_rounded, "Look Around",
                  "Drag to look around in 360°. Scroll or pinch to zoom."),
              _buildHelpItem(Icons.album_rounded, "Hotspots",
                  "Click on glowing circles to move to connected areas."),
              _buildHelpItem(Icons.arrow_back_rounded, "Go Back",
                  "Use the back button in the top-right to return to the previous screen."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: ndmuGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Got it!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ndmuGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ndmuGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
