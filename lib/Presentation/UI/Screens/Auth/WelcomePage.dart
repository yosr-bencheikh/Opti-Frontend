import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/core/styles/text_styles.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _buttonController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _buttonFadeAnimation;
  late final Animation<Offset> _slideInTextAnimation;
  late final Animation<double> _scaleButtonAnimation;
  late final Animation<double> _zoomImageAnimation;

  late int _currentImageIndex;
  late PageController _pageController;
  bool _showButton = false;
  bool _isPageViewReady = false;

  final List<String> _welcomeImages = [
    'assets/images/Virtualreality.gif',
    'assets/images/AR1.avif',
    'assets/images/image.jpg',
  ];

  final List<Map<String, String>> _welcomeTexts = [
    {
      'title': 'Bienvenue sur OptiApp',
      'subtitle':
          'Votre assistant numérique pour une gestion simplifiée des opticiens.',
      'description':
          'Une solution moderne pour les professionnels de l\'optique.'
    },
    {
      'title': 'Gestion Intelligente',
      'subtitle': 'Optimisez votre travail avec nos outils innovants.',
      'description':
          'Simplifiez vos tâches quotidiennes grâce à l\'intelligence artificielle.'
    },
    {
      'title': 'Commencez Maintenant',
      'subtitle': 'Rejoignez la révolution digitale de l\'optique.',
      'description': 'Découvrez une nouvelle façon de gérer votre activité.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;
    _pageController = PageController();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );

    _slideInTextAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleButtonAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _zoomImageAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start initial animations
    _controller.forward();

    // Delay the start of image sequence to ensure PageView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isPageViewReady = true;
      });
      _startImageSequence();
    });
  }

  void _startImageSequence() {
    if (!mounted || !_isPageViewReady) return;
    _showNextImage(0);
  }

  void _showNextImage(int index) {
    if (!mounted || !_isPageViewReady) return;

    setState(() {
      _currentImageIndex = index;
    });

    try {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // Handle any animation errors silently
      debugPrint('Page animation error: $e');
    }

    if (index < _welcomeImages.length - 1) {
      Future.delayed(const Duration(seconds: 2), () {
        _showNextImage(index + 1);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showButton = true;
          });
          _buttonController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations
            .welcomeGradientDecoration, // Using the gradient background
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Stack(
            children: [
              // Background pattern
              CustomPaint(
                painter: ImprovedPatternPainter(),
                size: Size.infinite,
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: AppDecorations
                          .welcomeLogoDecoration, // Custom logo decoration
                    ),

                    const SizedBox(height: 30),

                    // Image carousel
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _welcomeImages.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Image container with decoration
                                Container(
                                  height: 300,
                                  width: 400,
                                  decoration: AppDecorations
                                      .welcomeImageDecoration, // Image decoration
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      _welcomeImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Page indicators
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _welcomeImages.length,
                                    (dotIndex) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      height: 8,
                                      width: _currentImageIndex == dotIndex
                                          ? 24
                                          : 8,
                                      decoration: BoxDecoration(
                                        color: _currentImageIndex == dotIndex
                                            ? AppColors.whiteColor
                                            : AppColors.whiteColor
                                                .withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black
                                                .withOpacity(0.1),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Title with AppTextStyles
                                Text(
                                  _welcomeTexts[index]['title']!,
                                  style: AppTextStyles
                                      .welcomeTitleStyle, // Applied welcome title style
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 15),

                                // Subtitle with AppTextStyles
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    _welcomeTexts[index]['subtitle']!,
                                    style: AppTextStyles
                                        .welcomeSubtitleStyle, // Applied welcome subtitle style
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Description with AppTextStyles
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                  child: Text(
                                    _welcomeTexts[index]['description']!,
                                    style: AppTextStyles
                                        .welcomeDescriptionStyle, // Applied description style
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              ),
                          );
                        },
                      ),
                    ),
                    if (_showButton)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        child: FadeTransition(
                          opacity: _buttonFadeAnimation,
                          child: ScaleTransition(
                            scale: _buttonFadeAnimation,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              style: AppDecorations
                                  .welcomeButtonStyle, // Custom button style
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Continuer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Background pattern painter
class ImprovedPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.whiteColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < size.width; i += 30) {
      for (var j = 0; j < size.height; j += 30) {
        if ((i + j) % 60 == 0) {
          canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 2, paint);
        } else {
          canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
