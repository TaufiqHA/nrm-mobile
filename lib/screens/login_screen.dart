import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'user/user_main_layout.dart';

class LoginScreen extends StatelessWidget {
  /// Parameter authService dipertahankan untuk kompatibilitas dengan caller lama
  final dynamic authService;

  const LoginScreen({super.key, this.authService});

  void _navigateToMain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserMainLayout(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 100),

                          // Methodist Cross & Flame Logo (Transparent PNG)
                          Image.asset(
                            'asset/image/logo_nrm_transparent.png',
                            height: 210,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 18),

                          // App Title: NRM (Merah Tebal)
                          const Text(
                            'NRM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE52020),
                              letterSpacing: 2.0,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle: (Nyanyian Rohani Methodist)
                          const Text(
                            '(Nyanyian Rohani Methodist)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentSky,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const Spacer(),

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
                                const SizedBox(height: 12),
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

                          const Spacer(),

                          // Footer: by : Estomihi FP Simatupang
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                bottom: 24.0,
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
                                  SizedBox(height: 2),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
