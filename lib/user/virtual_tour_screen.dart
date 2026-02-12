import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  String _currentLocation = "Library Entrance";
  String _currentSceneId = "697825f6f7083bc155590495";
  bool _isLoading = true;

  // NDMU Colors
  final Color ndmuGreen = const Color(0xFF1B5E20);
  final Color ndmuGold = const Color(0xFFFFA000);

  @override
  void initState() {
    super.initState();
    _registerWrapperView();
    _setupMessageListener();
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
            if (mounted) {
              setState(() => _isLoading = false);
            }
          } else if (type == 'navigationStarted') {
            debugPrint('🎯 Navigation started: ${data['scene']}');
            if (mounted) {
              setState(() => _isLoading = true);
            }
          }
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
    });
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
    const entranceSceneId = "697825f6f7083bc155590495";
    _navigateToScene(
      TourSection(title: "Library Entrance", sceneId: entranceSceneId),
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
      appBar: AppBar(
        backgroundColor: ndmuGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.school, size: 24),
            const SizedBox(width: 8),
            const Text(
              "NDMU Virtual Tour",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            tooltip: 'Go to Entrance',
            onPressed: _resetTour,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Help',
            onPressed: _showHelp,
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
              bottom: 20,
              left: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ndmuGreen, ndmuGreen.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: ndmuGold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ndmuGreen, ndmuGreen.withOpacity(0.8)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.library_books,
                      color: ndmuGreen,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "NDMU LIBRARY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Virtual Tour Navigator",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Sections list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: libraryFloors.length,
                itemBuilder: (context, index) {
                  final floor = libraryFloors[index];
                  return _buildFloorSection(floor);
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        "Currently viewing:",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentLocation,
                    style: TextStyle(
                      color: ndmuGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorSection(FloorData floor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ndmuGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.layers, color: ndmuGreen, size: 24),
        ),
        title: Text(
          floor.floorName,
          style: TextStyle(
            color: ndmuGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${floor.sections.length} sections',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        children: floor.sections.map((section) {
          final isCurrent = section.sceneId == _currentSceneId;
          return InkWell(
            onTap: () => _navigateToScene(section),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isCurrent ? ndmuGreen.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent ? ndmuGreen : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrent ? Icons.location_on : Icons.location_on_outlined,
                    color: isCurrent ? ndmuGold : Colors.grey[400],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent ? ndmuGreen : Colors.black87,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ndmuGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ndmuGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_center, color: ndmuGreen, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Navigation Guide",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.menu,
                "Side Menu",
                "Open the menu (☰) to see all library sections organized by floor.",
              ),
              _buildHelpItem(
                Icons.touch_app,
                "Quick Navigation",
                "Tap any section name to instantly jump to that location.",
              ),
              _buildHelpItem(
                Icons.threed_rotation,
                "Look Around",
                "Drag with mouse/finger to look around in 360°. Scroll or pinch to zoom.",
              ),
              _buildHelpItem(
                Icons.album,
                "Hotspots",
                "Click on glowing circles (hotspots) to move to connected areas.",
              ),
              _buildHelpItem(
                Icons.home,
                "Return Home",
                "Use the home button (🏠) in the top bar to return to the entrance.",
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Got it!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ndmuGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ndmuGreen, size: 24),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
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
