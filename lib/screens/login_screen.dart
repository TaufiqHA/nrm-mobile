import 'package:flutter/material.dart';
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
          image: DecorationImage(
            image: AssetImage('asset/image/background.jpeg'),
            fit: BoxFit.cover,
          ),
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
                          const SizedBox(height: 28),

                          // Methodist Cross & Flame Logo (Transparent PNG)
                          Image.asset(
                            'asset/image/logo_nrm_transparent.png',
                            height: 125,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 16),

                          // App Title: NRM (Bold Red)
                          const Text(
                            'NRM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE52020),
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Subtitle: (Nyanyian Rohani Methodist) (Royal Blue)
                          const Text(
                            '(Nyanyian Rohani Methodist)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 38),

                          // Welcome & Description Text (Bold Red)
                          const Text(
                            'Selamat datang....\n'
                            'Aplikasi ini berisi lagu-lagu dari buku\n'
                            'Nyanyian Rohani Methodist (NRM)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE52020),
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Red Pill Button with "ok" text
                          SizedBox(
                            width: 155,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => _navigateToMain(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE52020),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: Colors.black.withValues(alpha: 0.3),
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'ok',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Guide Text Below Button
                          const Text(
                            'klik OK untuk melanjutkan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(height: 32),

                          // Footer: provided by
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                bottom: 20.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'provided by :',
                                    style: TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    'Estomihi FP Simatupang',
                                    style: TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    'Jemaat GMI Jakarta Pusat',
                                    style: TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
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
