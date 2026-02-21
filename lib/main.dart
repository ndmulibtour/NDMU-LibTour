import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:ndmu_libtour/admin/admin_dashboard.dart';
import 'package:ndmu_libtour/user/about_screen.dart';
import 'package:ndmu_libtour/user/contact_feedback_screen.dart';
import 'package:ndmu_libtour/user/policies_screen.dart';
import 'package:ndmu_libtour/director/director_dashboard.dart';
import 'package:ndmu_libtour/login_screen.dart';
import 'package:ndmu_libtour/user/faq_screen.dart';
import 'package:ndmu_libtour/user/home_screen.dart';
import 'package:ndmu_libtour/user/sections_screen.dart';
import 'package:ndmu_libtour/user/widgets/user_type_dialog.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'services/auth_service.dart';
import 'utils/fade_page_route.dart';
import 'utils/web_utils.dart' if (dart.library.io) 'utils/web_utils_stub.dart';
import 'package:ndmu_libtour/user/virtual_tour_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register web view factories if running on web
  if (kIsWeb) {
    registerWebViewFactories();
  }

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBmxYfQgFLVppQdZbhDPn7uEPCwbqTbITc",
      authDomain: "ndmu-libtour-49650.firebaseapp.com",
      projectId: "ndmu-libtour-49650",
      storageBucket: "ndmu-libtour-49650.firebasestorage.app",
      messagingSenderId: "905731281081",
      appId: "1:905731281081:web:a3b95082ae582be9654b68",
      measurementId: "G-Q5QGJYNQ2W",
    ),
  );

  runApp(const LibTour());
}

class LibTour extends StatelessWidget {
  const LibTour({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'NDMU Libtour',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            primary: const Color(0xFF1B5E20),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        home: const MainNavigator(),
        onGenerateRoute: (settings) {
          // Handle special routes that don't use the main navigator
          Widget? page;
          switch (settings.name) {
            case '/login':
              page = const LoginScreen();
              break;
            case '/admin':
              page = const AdminDashboard();
              break;
            case '/director':
              page = const DirectorDashboard();
              break;
            case '/virtual-tour':
              // arguments is a Map passed from home_screen or sections_screen:
              //   {'source': 'home'}                          — from home_screen
              //   {'source': 'sections', 'sceneId': '…'}     — from sections_screen
              final args = settings.arguments;
              String? sceneId;
              String? source;
              if (args is Map) {
                source = args['source'] as String?;
                sceneId = args['sceneId'] as String?;
              }
              page = VirtualTourScreen(initialSceneId: sceneId, source: source);
              break;
          }

          if (page != null) {
            return FadePageRoute(
              page: page,
              settings: settings,
            );
          }

          return null;
        },
      ),
    );
  }
}

// Navigation Provider to manage current page index
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String get currentRoute {
    switch (_currentIndex) {
      case 0:
        return '/';
      case 1:
        return '/sections';
      case 2:
        return '/policies';
      case 3:
        return '/faq';
      case 4:
        return '/contact';
      case 5:
        return '/about';
      default:
        return '/';
    }
  }
}

// Main Navigator Widget - Keeps all screens alive
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // List of screens to keep alive
  final List<Widget> _screens = const [
    HomeScreen(),
    LibrarySectionsScreen(),
    PoliciesScreen(),
    FAQScreen(),
    ContactFeedbackScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // ── Show user-type dialog on first visit ──────────────────────────────────
    // addPostFrameCallback ensures the widget tree is fully built before
    // showDialog is called — avoids "context not yet attached" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UserTypeDialog.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return IndexedStack(
          index: navProvider.currentIndex,
          children: _screens,
        );
      },
    );
  }
}
