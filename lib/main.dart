import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:ndmu_libtour/admin/admin_dashboard.dart';
import 'package:ndmu_libtour/user/contact_feedback_screen.dart';
import 'package:ndmu_libtour/create_account_screen.dart';
import 'package:ndmu_libtour/director/director_dashboard.dart';
import 'package:ndmu_libtour/login_screen.dart';
import 'package:ndmu_libtour/user/faq_screen.dart';
import 'package:ndmu_libtour/user/home_screen.dart';
import 'package:ndmu_libtour/user/sections_screen.dart';
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
      ],
      child: MaterialApp(
        title: 'NDMU Libtour',
        debugShowCheckedModeBanner: false,

        // Add localization delegates - THIS IS REQUIRED FOR FLUTTER QUILL
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate, // THIS IS THE MISSING DELEGATE
        ],
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('es', 'ES'), // Spanish
          // Add more locales as needed
        ],

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            primary: const Color(0xFF1B5E20),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
          // Add page transition theme for smooth animations
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
        initialRoute: '/',
        // Replace routes with onGenerateRoute for custom transitions
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/':
              page = const HomeScreen();
              break;
            case '/sections':
              page = const LibrarySectionsScreen();
              break;
            case '/faq':
              page = const FAQScreen();
              break;
            case '/contact':
              page = const ContactFeedbackScreen();
              break;
            case '/login':
              page = const LoginScreen();
              break;
            case '/create-account':
              page = const CreateAccountScreen();
              break;
            case '/admin':
              page = const AdminDashboard();
              break;
            case '/director':
              page = const DirectorDashboard();
              break;
            case '/virtual-tour':
              page = const VirtualTourScreen();
              break;
            default:
              page = const HomeScreen();
          }

          return FadePageRoute(
            page: page,
            settings: settings,
          );
        },
      ),
    );
  }
}
