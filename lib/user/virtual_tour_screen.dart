import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Web-only imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;

import 'package:ndmu_libtour/user/models/tour_sections.dart';

class VirtualTourScreen extends StatefulWidget {
  const VirtualTourScreen({super.key});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  final String _viewID = 'panoee-wrapper-view';
  String _currentLocation = "Outside Library";
  String _currentSceneId =
      "6978265df7083ba3665904a6"; // Default: Outside Library
  bool _isLoading = true;
  int? _expandedFloorIndex; // Track which floor is expanded

  // NDMU Colors
  final Color ndmuGreen = const Color(0xFF1B5E20);
  final Color ndmuGold = const Color(0xFFFFD700);
  final Color ndmuDarkGreen = const Color(0xFF0D3F0F);

  @override
  void initState() {
    super.initState();
    _registerWrapperView();
    _setupMessageListener();
    // Auto-expand the floor containing the current scene
    _updateExpandedFloor();
  }

  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      final data = event.data;

      if (data is Map) {
        try {
          final type = data['type'];

          if (type == 'wrapperReady') {
            debugPrint('✅ Wrapper is ready');
          } else if (type == 'tourLoaded') {
            debugPrint('✅ Tour loaded');

            // Extract scene info from tourLoaded message
            final sceneId = data['scene'] as String?;
            if (sceneId != null && mounted) {
              _updateCurrentScene(sceneId);
            }

            if (mounted) {
              setState(() => _isLoading = false);
            }
          } else if (type == 'navigationStarted') {
            debugPrint('🎯 Navigation started: ${data['scene']}');

            // Update current scene immediately when navigation starts
            final sceneId = data['scene'] as String?;
            final sceneName = data['name'] as String?;

            if (sceneId != null && mounted) {
              setState(() {
                _currentSceneId = sceneId;
                if (sceneName != null) {
                  _currentLocation = sceneName;
                }
                _isLoading = true;
                _updateExpandedFloor(); // Auto-expand the correct floor
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
    });
  }

  /// Update current scene and find its name from tour sections
  void _updateCurrentScene(String sceneId) {
    String? foundName;

    // Search through all floors and sections to find the scene name
    for (var floor in libraryFloors) {
      for (var section in floor.sections) {
        if (section.sceneId == sceneId) {
          foundName = section.title;
          break;
        }
      }
      if (foundName != null) break;
    }

    setState(() {
      _currentSceneId = sceneId;
      if (foundName != null) {
        _currentLocation = foundName;
      }
      _updateExpandedFloor();
    });
  }

  /// Find which floor contains the current scene and set it as expanded
  void _updateExpandedFloor() {
    for (int i = 0; i < libraryFloors.length; i++) {
      final floor = libraryFloors[i];
      for (var section in floor.sections) {
        if (section.sceneId == _currentSceneId) {
          setState(() {
            _expandedFloorIndex = i;
          });
          return;
        }
      }
    }
  }

  void _registerWrapperView() {
    // Register the wrapper iframe ONCE
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewID, (int viewId) {
      final iframe = html.IFrameElement()
        ..id = 'panoee-wrapper-iframe'
        ..src = '/panoee_tour.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; xr-spatial-tracking'
        ..allowFullscreen = true;

      iframe.onLoad.listen((_) {
        debugPrint('Wrapper iframe loaded');
      });

      return iframe;
    });
  }

  void _navigateToScene(TourSection section) {
    if (section.sceneId == _currentSceneId) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    debugPrint(
        '🎯 Requesting navigation to: ${section.title} (${section.sceneId})');

    setState(() {
      _currentLocation = section.title;
      _currentSceneId = section.sceneId;
      _isLoading = true;
      _updateExpandedFloor();
    });

    // Close drawer
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Send message to wrapper
    _sendNavigationMessage(section);
  }

  void _sendNavigationMessage(TourSection section) {
    try {
      final wrapperIframe = html.document
          .getElementById('panoee-wrapper-iframe') as html.IFrameElement?;

      if (wrapperIframe != null && wrapperIframe.contentWindow != null) {
        final message = {
          'action': 'navigateToScene',
          'sceneId': section.sceneId,
          'sceneName': section.title,
        };

        wrapperIframe.contentWindow!.postMessage(message, '*');
        debugPrint('📤 Navigation message sent: ${section.title}');
      } else {
        debugPrint('❌ Wrapper iframe not found');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error sending navigation message: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetTour() {
    const defaultSceneId = "6978265df7083ba3665904a6"; // Outside Library
    _navigateToScene(
      TourSection(title: "Outside Library", sceneId: defaultSceneId),
    );
  }

  void _toggleIFrameInteraction(bool interactive) {
    final iframe = html.document.getElementById('panoee-wrapper-iframe');
    if (iframe != null) {
      iframe.style.pointerEvents = interactive ? 'auto' : 'none';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: ndmuGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ndmuGreen, ndmuDarkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFFFD700), width: 3),
            ),
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/ndmu_logo.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    size: 35,
                    color: Color(0xFF1B5E20)),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Virtual Tour",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "NDMU Library Navigator",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Return to Outside',
              onPressed: _resetTour,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
              tooltip: 'Help',
              onPressed: _showHelp,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      onDrawerChanged: (isOpen) {
        _toggleIFrameInteraction(!isOpen);
      },
      drawer: _buildSidebar(),
      body: Stack(
        children: [
          // Single wrapper view - never changes
          const Positioned.fill(
            child: HtmlElementView(
              viewType: 'panoee-wrapper-view',
            ),
          ),

          // Current location badge
          if (!_isLoading)
            Positioned(
              bottom: 24,
              left: 24,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(30),
                shadowColor: ndmuGreen.withOpacity(0.4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ndmuGreen, ndmuGreen.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ndmuGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Current Location",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentLocation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
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
                      // Header with NDMU Logo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ndmuGreen, ndmuDarkGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ndmuGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ndmuGold.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/ndmu_logo.png',
                                    height: 36,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.school,
                                            size: 36,
                                            color: ndmuGreen),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "NDMU LIBRARY",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Virtual Tour Navigator",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Floor sections list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: libraryFloors.length,
                          itemBuilder: (context, index) {
                            return _buildFloorSection(
                                libraryFloors[index], index);
                          },
                        ),
                      ),

                      // Current location footer
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey[200]!, width: 1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
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
                                          colors: [ndmuGreen, ndmuDarkGreen],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Currently viewing",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ndmuGreen.withValues(alpha: 0.1),
                                        ndmuGreen.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: ndmuGold.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: ndmuGold,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _currentLocation,
                                          style: TextStyle(
                                            color: ndmuGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))));
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
                        Colors.white.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.6),
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
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedFloorIndex = expanded ? floorIndex : null;
                  });
                },
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
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    color: (isExpanded || hasCurrentScene)
                        ? (isExpanded ? ndmuGreen : Colors.white)
                        : Colors.grey[600],
                    size: 22,
                  ),
                ),
                title: Text(
                  floor.floorName,
                  style: TextStyle(
                    color: isExpanded
                        ? ndmuGreen
                        : hasCurrentScene
                            ? ndmuGreen
                            : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${floor.sections.length} section${floor.sections.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
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
                            child: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent ? ndmuGreen : Colors.black87,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [ndmuGold, ndmuGold.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: ndmuGold.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
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
                  colors: [ndmuGreen, ndmuGreen.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_center_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Navigation Guide",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.menu_rounded,
                "Side Menu",
                "Open the menu (☰) to see all library sections organized by floor.",
              ),
              _buildHelpItem(
                Icons.touch_app_rounded,
                "Quick Navigation",
                "Tap any section name to instantly jump to that location.",
              ),
              _buildHelpItem(
                Icons.threed_rotation_rounded,
                "Look Around",
                "Drag with mouse/finger to look around in 360°. Scroll or pinch to zoom.",
              ),
              _buildHelpItem(
                Icons.album_rounded,
                "Hotspots",
                "Click on glowing circles (hotspots) to move to connected areas.",
              ),
              _buildHelpItem(
                Icons.home_rounded,
                "Return Home",
                "Use the home button (🏠) in the top bar to return to the outside entrance.",
              ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Got it!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
