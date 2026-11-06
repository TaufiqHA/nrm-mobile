import 'package:flutter/material.dart';

import '../core/services/api_application_service.dart';
import '../core/services/api_category_service.dart';
import '../core/services/application_service.dart';
import '../core/services/category_service.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/category_icon_helper.dart';
import '../models/category_model.dart';
import '../models/display_mode.dart';
import '../widgets/ad_popup.dart';
import 'user/user_main_layout.dart';
import 'music/music_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Parameter authService dipertahankan untuk kompatibilitas dengan caller lama
  final dynamic authService;
  final CategoryService? categoryService;
  final ApplicationService? applicationService;

  const LoginScreen({
    super.key,
    this.authService,
    this.categoryService,
    this.applicationService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final CategoryService _categoryService;
  late final ApplicationService _applicationService;
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _categoryLoadFailed = false;
  bool _homeAdShown = false;

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? ApiCategoryService();
    _applicationService = widget.applicationService ?? ApiApplicationService();
    _loadCategories();
    _loadAppConfig();
  }

  Future<void> _loadAppConfig() async {
    try {
      final config = await _applicationService.getApplicationConfig();
      if (!mounted || !config.isAdsHomeActive) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _homeAdShown) return;
        if (!hasAdPopupContent(config.adsHomeConfig)) return;
        _homeAdShown = true;
        showAdPopup(context, config.adsHomeConfig);
      });
    } catch (e) {
      debugPrint('Login screen app config load error: $e');
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadFailed = false;
    });

    try {
      final categories = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        // Kategori yang dinonaktifkan lewat admin tidak boleh tampil ke user.
        _categories = categories
            .where((category) => category.isActive)
            .toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat kategori di halaman landing: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoryLoadFailed = true;
      });
    }
  }

  void _navigateToMain(
    BuildContext context, {
    int? categoryId,
    DisplayMode displayMode = DisplayMode.normal,
  }) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserMainLayout(
          initialCategoryFilter: categoryId,
          initialDisplayMode: displayMode,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _openMusic(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 760;
              final logoHeight = isCompactHeight ? 126.0 : 186.0;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isCompactHeight ? 8 : 14),

                          // Methodist Cross & Flame Logo (Transparent PNG)
                          SizedBox(
                            height: logoHeight,
                            child: Image.asset(
                              'asset/image/logo_nrm_transparent.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          SizedBox(height: isCompactHeight ? 10 : 16),

                          // App Title: NRM (Merah Tebal)
                          Text(
                            'NRM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompactHeight ? 46 : 58,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFE52020),
                              letterSpacing: 2.0,
                            ),
                          ),

                          SizedBox(height: isCompactHeight ? 4 : 8),

                          // Subtitle: (Nyanyian Rohani Methodist)
                          Text(
                            '(Nyanyian Rohani Methodist)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompactHeight ? 15 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentSky,
                              letterSpacing: 0.2,
                            ),
                          ),

                          SizedBox(height: isCompactHeight ? 18 : 24),

                          // Pilihan kategori & mode tampilan dalam satu baris ikon.
                          // Ketuk salah satu untuk langsung masuk.
                          SizedBox(
                            key: const ValueKey('landing_category_selector'),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: isCompactHeight ? 8 : 10),
                                _buildSelectionRow(context),
                                if (_categoryLoadFailed &&
                                    !_isLoadingCategories &&
                                    _categories.isEmpty)
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      onPressed: _loadCategories,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                        color: AppColors.accentSky,
                                      ),
                                      label: const Text(
                                        'Muat ulang kategori',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.accentSky,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(height: isCompactHeight ? 18 : 24),
                        ],
                      ),
                    ),
                  ),

                  // Footer terpusat dan diangkat dari dasar layar, berada di
                  // bawah baris tombol kategori dan mode lirik only.
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      4,
                      24,
                      (constraints.maxHeight * 0.12).clamp(56.0, 150.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'by : Estomihi FP Simatupang',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jemaat GMI Jakarta Pusat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionRow(BuildContext context) {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentSky),
            ),
          ),
        ),
      );
    }

    final tiles = <Widget>[
      for (var index = 0; index < _categories.length; index++)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(width: 92, child: _buildCategoryTile(context, index)),
        ),
      SizedBox(
        width: 92,
        child: _IconOptionTile(
          key: const ValueKey('landing_menu_music'),
          icon: Icons.library_music_rounded,
          color: const Color(0xFF7C4DFF),
          label: 'BUKU MERAH (Musik)',
          selected: false,
          labelMaxLines: 2,
          onTap: () => _openMusic(context),
        ),
      ),
      SizedBox(
        width: 92,
        child: _IconOptionTile(
          key: const ValueKey('landing_mode_text_only'),
          icon: Icons.text_snippet_rounded,
          color: const Color(0xFFFB8C00),
          label: 'BUKU MERAH (Lirik)',
          selected: false,
          labelMaxLines: 2,
          onTap: () {
            _navigateToMain(context, displayMode: DisplayMode.textOnly);
          },
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tiles,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTile(BuildContext context, int index) {
    final category = _categories[index];
    final spec = categoryIconSpec(category, index);

    return _IconOptionTile(
      key: ValueKey('landing_category_${category.songcategoryid}'),
      icon: spec.icon,
      color: spec.color,
      imageUrl: spec.imageUrl,
      label: category.name,
      selected: false,
      labelMaxLines: 4,
      onTap: () {
        _navigateToMain(context, categoryId: category.songcategoryid);
      },
    );
  }
}

class _IconOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final String label;
  final bool selected;
  final int labelMaxLines;
  final VoidCallback? onTap;

  const _IconOptionTile({
    super.key,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.label,
    required this.selected,
    this.labelMaxLines = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentCyan.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.accentCyan.withValues(alpha: 0.75)
                    : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            Color.lerp(color, Colors.black, 0.28)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                              alpha: selected ? 0.55 : 0.28,
                            ),
                            blurRadius: selected ? 14 : 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: imageUrl == null
                            ? Stack(
                                children: [
                                  // Kilau lembut agar ikon terasa seperti app icon.
                                  Positioned(
                                    top: 4,
                                    left: 6,
                                    right: 6,
                                    child: Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              )
                            // Ikon unggahan memenuhi kotak tanpa padding sama
                            // sekali; kelebihan gambar dipotong mengikuti sudut.
                            : Image.network(
                                imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF061121),
                              width: 1.6,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Color(0xFF061121),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: labelMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
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
