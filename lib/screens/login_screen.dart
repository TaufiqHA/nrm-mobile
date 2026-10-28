import 'package:flutter/material.dart';

import '../core/services/api_category_service.dart';
import '../core/services/category_service.dart';
import '../core/theme/app_colors.dart';
import '../models/category_model.dart';
import 'user/user_main_layout.dart';

class LoginScreen extends StatefulWidget {
  /// Parameter authService dipertahankan untuk kompatibilitas dengan caller lama
  final dynamic authService;
  final CategoryService? categoryService;

  const LoginScreen({super.key, this.authService, this.categoryService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final CategoryService _categoryService;
  List<CategoryModel> _categories = [];
  int? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _categoryLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? ApiCategoryService();
    _loadCategories();
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
        _categories = categories;
        _isLoadingCategories = false;
        if (categories.isNotEmpty) {
          _selectedCategory ??= categories.first.songcategoryid;
        }
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

  void _navigateToMain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserMainLayout(initialCategoryFilter: _selectedCategory),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Lebar kotak kategori mengikuti teks kategori terpanjang.
  double _categorySelectorWidth(double availableWidth) {
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    const chromeWidth =
        20.0 + 10.0 + 26.0 + 28.0 + 8.0; // ikon, jarak, panah, padding, buffer

    // Nama kategori terpanjang yang harus selalu muat di kotak, meskipun
    // kategori tersebut belum ada di data API saat ini.
    const referenceLongestName = 'Indonesia Lirik + Musik (buku merah)';

    final texts = <String>[
      referenceLongestName,
      ..._categories
          .map((cat) => cat.name)
          .where((name) => name.trim().isNotEmpty),
    ];
    if (texts.length == 1) {
      texts.add('Kategori tidak tersedia');
    }

    double longestText = 0;
    for (final text in texts) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > longestText) {
        longestText = painter.width;
      }
    }

    final safeMaxWidth = availableWidth > 0 ? availableWidth : 260.0;
    final minWidth = safeMaxWidth < 260.0 ? safeMaxWidth : 260.0;
    final desiredWidth = longestText + chromeWidth;

    if (desiredWidth < minWidth) return minWidth;
    if (desiredWidth > safeMaxWidth) return safeMaxWidth;
    return desiredWidth;
  }

  Widget _buildCategorySelector() {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE52020).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.category_rounded,
            size: 20,
            color: AppColors.accentSky,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedCategory,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                hint: Text(
                  _isLoadingCategories
                      ? 'Memuat kategori...'
                      : 'Kategori tidak tersedia',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int?>(
                    value: cat.songcategoryid,
                    child: Text(cat.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _categories.isEmpty
                    ? null
                    : (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
              ),
            ),
          ),
        ],
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
              final isCompactHeight = constraints.maxHeight < 750;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: isCompactHeight ? 8 : 12),

                    // Methodist Cross & Flame Logo (Transparent PNG)
                    // Mengisi sisa ruang vertikal agar tidak ada ruang kosong besar.
                    Expanded(
                      child: Image.asset(
                        'asset/image/logo_nrm_transparent.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 12 : 20),

                    // App Title: NRM (Merah Tebal)
                    Text(
                      'NRM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompactHeight ? 52 : 60,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE52020),
                        letterSpacing: 2.0,
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 8 : 12),

                    // Subtitle: (Nyanyian Rohani Methodist)
                    Text(
                      '(Nyanyian Rohani Methodist)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompactHeight ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentSky,
                        letterSpacing: 0.2,
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 20 : 28),

                    // Filter Kategori
                    SizedBox(
                      key: const ValueKey('landing_category_selector'),
                      width: _categorySelectorWidth(constraints.maxWidth - 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Pilih Jenis Musik',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: isCompactHeight ? 8 : 10),
                          _buildCategorySelector(),
                          if (_categoryLoadFailed &&
                              !_isLoadingCategories &&
                              _categories.isEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _loadCategories,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
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

                    SizedBox(height: isCompactHeight ? 20 : 28),

                    // Red Circular Play Button with "Klik to play"
                    GestureDetector(
                      onTap: () => _navigateToMain(context),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE52020),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompactHeight ? 10 : 14),
                          const Text(
                            'Klik to play',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 16 : 24),

                    // Footer: by : Estomihi FP Simatupang
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isCompactHeight ? 18 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'by : Estomihi FP Simatupang',
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
