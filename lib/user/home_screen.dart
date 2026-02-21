import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:ndmu_libtour/admin/services/system_settings_service.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/services/analytics_service.dart';
import '../utils/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════

const _kGreen = Color(0xFF1B5E20);
const _kGreenMid = Color(0xFF2E7D32);
const _kGold = Color(0xFFFFD700);
const _kGoldDeep = Color(0xFFFFC107);

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _DbItem {
  final String name;
  final String asset;
  final String url;
  const _DbItem({required this.name, required this.asset, required this.url});
}

class _DeweyCategory {
  final String code;
  final String title;
  final Color headerColor;
  final Color headerTextColor;
  final Color bodyBg;
  final List<String> subs;
  const _DeweyCategory({
    required this.code,
    required this.title,
    required this.headerColor,
    required this.headerTextColor,
    required this.bodyBg,
    required this.subs,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// STATIC DATA
// ══════════════════════════════════════════════════════════════════════════════

const List<_DbItem> _kDatabases = [
  _DbItem(
    name: 'Bloomsbury Architecture Library',
    asset: 'assets/images/subscribed_OL_DB/bloomsbury architecture library.png',
    url: 'https://www.bloomsbury.com/us/',
  ),
  _DbItem(
    name: 'CD Asia Online',
    asset: 'assets/images/subscribed_OL_DB/CD asia online.jpg',
    url: 'https://cdasia.com/',
  ),
  _DbItem(
    name: 'De Gruyter eBooks',
    asset: 'assets/images/subscribed_OL_DB/de-gruyter-ebooks.jpg',
    url: 'https://www.degruyterbrill.com/',
  ),
  _DbItem(
    name: 'EBSCO Advanced Starter',
    asset: 'assets/images/subscribed_OL_DB/EBSCO ebooks.png',
    url: 'https://www.ebsco.com/',
  ),
  _DbItem(
    name: 'Gale Research Complete',
    asset: 'assets/images/subscribed_OL_DB/gale-research-complete.jpg',
    url: 'https://www.gale.com/',
  ),
  _DbItem(
    name: 'Philippine e-Journals Premium',
    asset: 'assets/images/subscribed_OL_DB/pej.png',
    url: 'https://ejournals.ph/',
  ),
  _DbItem(
    name: 'ProQuest Academic Complete',
    asset: 'assets/images/subscribed_OL_DB/ProQuest academic complete.jpg',
    url: 'https://www.proquest.com/',
  ),
  _DbItem(
    name: 'ProQuest Central',
    asset: 'assets/images/subscribed_OL_DB/Proquest Central.jpg',
    url: 'https://about.proquest.com/en/',
  ),
  _DbItem(
    name: 'Wiley Online Books',
    asset: 'assets/images/subscribed_OL_DB/wiley online books.gif',
    url: 'https://onlinelibrary.wiley.com/',
  ),
];

// Alternating green / gold theme — mirrors NDMU brand palette
const List<_DeweyCategory> _kDewey = [
  _DeweyCategory(
    code: '000', title: 'GENERALITIES',
    headerColor: Color(0xFFFF5C00), // orange sticker
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFFFF3E0),
    subs: [
      '010  Bibliography',
      '020  Library & information sciences',
      '030  General encyclopedic works',
      '040  Unassigned',
      '050  General serials & their indexes',
      '060  General organizations & museology',
      '070  News media, journalism, publishing',
      '080  General collections',
      '090  Manuscripts & rare books',
    ],
  ),
  _DeweyCategory(
    code: '100', title: 'PHILOSOPHY & PSYCHOLOGY',
    headerColor: Color(0xFFE53935), // red sticker
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFFFEBEE),
    subs: [
      '110  Metaphysics',
      '120  Epistemology, causation, humankind',
      '130  Paranormal phenomena, occult',
      '140  Specific philosophical schools',
      '150  Psychology',
      '160  Logic',
      '170  Ethics (moral philosophy)',
      '180  Ancient, medieval, Oriental philosophy',
      '190  Modern Western philosophy',
    ],
  ),
  _DeweyCategory(
    code: '200', title: 'RELIGION',
    headerColor: Color(0xFF8E44AD), // purple sticker
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFF3E5F5),
    subs: [
      '210  Natural theology',
      '220  Bible',
      '230  Christian theology',
      '240  Christian moral & devotional theology',
      '250  Christian orders & local church',
      '260  Christian social theology',
      '270  Christian church history',
      '280  Christian denominations & sects',
      '290  Other & comparative religions',
    ],
  ),
  _DeweyCategory(
    code: '300', title: 'SOCIAL SCIENCES',
    headerColor: Color(0xFFCCE000), // yellow-green sticker
    headerTextColor: Color(0xFF1A1A1A),
    bodyBg: Color(0xFFF9FFD0),
    subs: [
      '310  General statistics',
      '320  Political science',
      '330  Economics',
      '340  Law',
      '350  Public administration',
      '360  Social services; associations',
      '370  Education',
      '380  Commerce, communications, transport',
      '390  Customs, etiquette, folklore',
    ],
  ),
  _DeweyCategory(
    code: '400', title: 'LANGUAGES',
    headerColor: Color(0xFFFFB733), // gold/tan sticker
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFFFF8DC),
    subs: [
      '410  Linguistics',
      '420  English & Old English',
      '430  Germanic languages German',
      '440  Romance languages French',
      '450  Italian, Romanian languages',
      '460  Spanish & Portuguese languages',
      '470  Italic languages, Latin',
      '480  Hellenic languages, Classical Greek',
      '490  Other languages',
    ],
  ),
  _DeweyCategory(
    code: '500', title: 'NATURAL SCIENCES & MATHEMATICS',
    headerColor: Color(0xFFFF0090), // hot-pink / magenta sticker
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFFCE4EC),
    subs: [
      '510  Mathematics',
      '520  Astronomy & allied sciences',
      '530  Physics',
      '540  Chemistry & allied sciences',
      '550  Earth sciences',
      '560  Paleontology, paleozoology',
      '570  Life sciences',
      '580  Botanical sciences',
      '590  Zoological sciences',
    ],
  ),
  _DeweyCategory(
    code: '600', title: 'TECHNOLOGY (APPLIED SCIENCES)',
    headerColor: Color(0xFF32CD32), // lime-green stickerr
    headerTextColor: Colors.white,
    bodyBg: Color(0xFFF1FFE8),
    subs: [
      '610  Medical sciences and medicine',
      '620  Engineering & allied operations',
      '630  Agriculture',
      '640  Home economics & family living',
      '650  Management & auxiliary services',
      '660  Chemical engineering',
      '670  Manufacturing',
      '680  Manufacture for specific uses',
      '690  Buildings',
    ],
  ),
  _DeweyCategory(
    code: '700', title: 'THE ARTS',
    headerColor: Color(0xFFE8DFA0), // cream / beige sticker
    headerTextColor: Color(0xFF3A3000),
    bodyBg: Color(0xFFFFFDE7),
    subs: [
      '710  Civic & landscape art',
      '720  Architecture',
      '730  Plastic arts, sculpture',
      '740  Drawing & decorative arts',
      '750  Painting & paintings (museums)',
      '760  Graphic arts, printmaking & prints',
      '770  Photography & photographs',
      '780  Music',
      '790  Recreational & performing arts',
    ],
  ),
  _DeweyCategory(
    code: '800', title: 'LITERATURE & RHETORIC',
    headerColor: Color(0xFF87CEEB), // sky-blue sticker
    headerTextColor: Color(0xFF0D2840),
    bodyBg: Color(0xFFE3F2FD),
    subs: [
      '810  American literature',
      '820  English & Old English literatures',
      '830  Literatures of Germanic languages',
      '840  Literatures of Romance languages',
      '850  Italian, Romanian literatures',
      '860  Spanish & Portuguese literatures',
      '870  Italic literatures, Latin',
      '880  Hellenic literatures, Classical Greek',
      '890  Literatures of other languages',
    ],
  ),
  _DeweyCategory(
    code: '900', title: 'GEOGRAPHY & HISTORY',
    headerColor: Color(0xFFFFB6C1), // light-pink sticker
    headerTextColor: Color(0xFF4A0010),
    bodyBg: Color(0xFFFCE4EC),
    subs: [
      '910  Geography and travel',
      '920  Biography, genealogy, insignia',
      '930  History of the ancient world',
      '940  General history of Europe',
      '950  General history of Asia, Far East',
      '960  General history of Africa',
      '970  General history of North America',
      '980  General history of South America',
      '990  General history of other areas',
    ],
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hero carousel
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _heroTimer;
  bool _visitLogged = false;

  // DB auto-scroll
  late ScrollController _dbScrollCtrl;
  Timer? _dbScrollTimer;

  final _settingsService = SystemSettingsService();

  final List<String> _carouselImages = [
    'assets/images/homepage/ndmu lib front.jpg',
    'assets/images/homepage/lib entrance.jpg',
    'assets/images/homepage/cscam.jpg',
  ];

  List<_DbItem> get _loopItems => [..._kDatabases, ..._kDatabases];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _currentPage = (_currentPage + 1) % _carouselImages.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    AnalyticsService().logPageView('home');
    if (!_visitLogged) {
      _visitLogged = true;
      AnalyticsService().logUniqueVisit();
    }

    _dbScrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDbScroll());
  }

  void _startDbScroll() {
    _dbScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_dbScrollCtrl.hasClients) return;
      final max = _dbScrollCtrl.position.maxScrollExtent;
      final pos = _dbScrollCtrl.offset;
      final half = max / 2;
      if (pos >= half) {
        _dbScrollCtrl.jumpTo(pos - half);
      } else {
        _dbScrollCtrl.jumpTo(pos + 0.55);
      }
    });
  }

  @override
  void dispose() {
    _heroTimer.cancel();
    _pageController.dispose();
    _dbScrollTimer?.cancel();
    _dbScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemSettings>(
      stream: _settingsService.watchSettings(),
      builder: (context, snap) {
        final settings = snap.data ?? SystemSettings.defaults();
        if (settings.isMaintenanceMode) return const _MaintenanceScreen();

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          appBar: const TopBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (settings.hasAnnouncement)
                  _AnnouncementBanner(text: settings.globalAnnouncement),
                _buildHeroSection(context),
                _buildDatabasesSection(context),
                _buildWebOpacBanner(context),
                _buildDeweySection(context),
                const BottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SizedBox(
      height: isMobile ? 550 : 750,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _carouselImages.length,
              itemBuilder: (_, i) => Image.asset(
                _carouselImages[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _kGreen,
                  child: const Center(
                      child:
                          Icon(Icons.image, color: Colors.white24, size: 100)),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kGreen.withOpacity(0.85),
                    _kGreen.withOpacity(0.60),
                    _kGreen.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: ResponsiveHelper.padding(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 24),
              desktop: const EdgeInsets.symmetric(horizontal: 80),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _kGold.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Image.asset('assets/images/ndmu_logo.png',
                        height: isMobile ? 60 : 100),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'NOTRE DAME OF MARBEL UNIVERSITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _kGold,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 800,
                    child: Text(
                      'Step Into the Future of Learning',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontSize(context,
                            mobile: 36, desktop: 64),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        shadows: const [
                          Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 2),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 700,
                    child: Text(
                      'Navigate through floors, browse sections, and discover resources\n'
                      'with our interactive 360° virtual tour of the NDMU Library.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.6,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4)
                          ]),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient:
                          const LinearGradient(colors: [_kGold, _kGoldDeep]),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/virtual-tour',
                          arguments: {'source': 'home'}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: _kGreen,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'START VIRTUAL TOUR',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — SUBSCRIBED ONLINE DATABASES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDatabasesSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final cardSize = isMobile ? 130.0 : 165.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: 60, bottom: isMobile ? 28 : 48),
      child: Column(
        children: [
          // Heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 40, height: 3, color: _kGold),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'SUBSCRIBED ONLINE DATABASES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(width: 40, height: 3, color: _kGold),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a database card to open it',
            style: TextStyle(
                color: Color(0xFF999999), fontSize: 12, letterSpacing: 0.3),
          ),
          const SizedBox(height: 28),

          // ── Dark green scrolling band ────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen, _kGreenMid],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 26),
            child: ScrollConfiguration(
              behavior: _HideScrollbar(),
              child: SingleChildScrollView(
                controller: _dbScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    ..._loopItems.map((item) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _DbCard(
                            item: item,
                            size: cardSize,
                            onTap: () => _launch(item.url),
                          ),
                        )),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── View All — mobile only ───────────────────────────────────────
          if (isMobile) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _showAllSheet(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kGreen, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_view_rounded, color: _kGreen, size: 17),
                      SizedBox(width: 8),
                      Text(
                        'VIEW ALL DATABASES',
                        style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              // Sheet header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kGreen, _kGreenMid]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              color: _kGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.library_books,
                              color: _kGold, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subscribed Online Databases',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15),
                              ),
                              Text(
                                'Tap any card to open in browser',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: _kGold.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${_kDatabases.length}',
                            style: const TextStyle(
                                color: _kGold,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: GridView.builder(
                  controller: sc,
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _kDatabases.length,
                  itemBuilder: (_, i) {
                    final item = _kDatabases[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _launch(item.url);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFE4E4E4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(
                                item.asset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.library_books,
                                    color: _kGreen,
                                    size: 36),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.3),
                            ),
                            const SizedBox(height: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_kGreen, _kGreenMid]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Open →',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — WEB OPAC (minimal gap, flush under databases)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebOpacBanner(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 48,
        0, // no top gap — sits right under databases section
        isMobile ? 20 : 48,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child:
              _WebOpacCard(onTap: () => _launch('http://web-opac.ndmu.edu.ph')),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — DEWEY DECIMAL CLASSIFICATION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDeweySection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      // Subtle off-white background so it reads as a distinct section
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F6F4), Color(0xFFEDF2ED)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.symmetric(
          vertical: isMobile ? 48 : 72, horizontal: isMobile ? 16 : 40),
      child: Column(
        children: [
          // ── Heading ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 3, color: _kGold),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'DEWEY DECIMAL CLASSIFICATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.5,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(width: 40, height: 3, color: _kGold),
            ],
          ),
          const SizedBox(height: 10),

          // NDMU subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ndmu_logo.png',
                height: 16,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, size: 15, color: _kGreen),
              ),
              const SizedBox(width: 7),
              const Flexible(
                child: Text(
                  'J.M.J. Marist Brothers · Notre Dame of Marbel University · University Library',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                      letterSpacing: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Instruction chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, color: _kGreen, size: 14),
                SizedBox(width: 5),
                Text(
                  'Tap a category to expand subcategories',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: _kGreen,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Grid ──────────────────────────────────────────────────────────
          isMobile
              ? Column(
                  children: _kDewey.map((c) => _DeweyBlock(cat: c)).toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: _kDewey
                            .sublist(0, 5)
                            .map((c) => _DeweyBlock(cat: c))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: _kDewey
                            .sublist(5)
                            .map((c) => _DeweyBlock(cat: c))
                            .toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENT — Database card (glassmorphism)
// ══════════════════════════════════════════════════════════════════════════════
class _DbCard extends StatefulWidget {
  final _DbItem item;
  final double size;
  final VoidCallback onTap;
  const _DbCard({required this.item, required this.size, required this.onTap});

  @override
  State<_DbCard> createState() => _DbCardState();
}

class _DbCardState extends State<_DbCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? Colors.white.withOpacity(0.22)
                        : Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hovered
                          ? _kGold.withOpacity(0.75)
                          : Colors.white.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withOpacity(_hovered ? 0.18 : 0.10),
                          blurRadius: _hovered ? 22 : 12)
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          widget.item.asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.library_books,
                              color: Colors.white54,
                              size: 36),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kGold.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Open →',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreen)),
                        ),
                      ),
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

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENT — WebOPAC card
// ══════════════════════════════════════════════════════════════════════════════
class _WebOpacCard extends StatefulWidget {
  final VoidCallback onTap;
  const _WebOpacCard({required this.onTap});

  @override
  State<_WebOpacCard> createState() => _WebOpacCardState();
}

class _WebOpacCardState extends State<_WebOpacCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered
                    ? _kGreen.withOpacity(0.10)
                    : _kGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _hovered
                      ? _kGold.withOpacity(0.70)
                      : _kGreen.withOpacity(0.20),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(_hovered ? 0.07 : 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.open_in_browser_rounded,
                        color: _kGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WebOPAC',
                          style: TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: 1.2),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Can be accessed through  web-opac.ndmu.edu.ph',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    transform:
                        Matrix4.translationValues(_hovered ? 5.0 : 0.0, 0, 0),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        color: _kGold, size: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENT — Dewey block (one expandable category)
// ══════════════════════════════════════════════════════════════════════════════
class _DeweyBlock extends StatefulWidget {
  final _DeweyCategory cat;
  const _DeweyBlock({required this.cat});

  @override
  State<_DeweyBlock> createState() => _DeweyBlockState();
}

class _DeweyBlockState extends State<_DeweyBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Tappable header ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              color: cat.headerColor,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  // Code badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cat.code,
                      style: TextStyle(
                          color: cat.headerTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.title,
                      style: TextStyle(
                          color: cat.headerTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          letterSpacing: 0.3),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: cat.headerTextColor.withOpacity(0.75), size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible subcategory list ─────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              color: cat.bodyBg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cat.subs.asMap().entries.map((e) {
                  final even = e.key.isEven;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: even
                          ? Colors.white.withOpacity(0.7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          margin: const EdgeInsets.only(right: 8, top: 1),
                          decoration: BoxDecoration(
                            color: cat.headerColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2C2C2C),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCROLLBAR HIDER
// ══════════════════════════════════════════════════════════════════════════════
class _HideScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

// ══════════════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT BANNER
// ══════════════════════════════════════════════════════════════════════════════
class _AnnouncementBanner extends StatefulWidget {
  final String text;
  const _AnnouncementBanner({required this.text});

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_kGold, _kGoldDeep]),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: _kGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.text,
                style: const TextStyle(
                    color: _kGreen, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18, color: _kGreen),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAINTENANCE SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGreen,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Image.asset(
                  'assets/images/ndmu_logo.png',
                  height: 100,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.school, size: 80, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              const Icon(Icons.construction, color: _kGold, size: 64),
              const SizedBox(height: 24),
              const Text(
                'System Under Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "We're making improvements to bring you\na better experience. Please check back soon.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                    color: _kGold, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              const Text(
                'NDMU LibTour — Notre Dame of Marbel University',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
