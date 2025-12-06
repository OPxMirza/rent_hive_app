import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_hive_app/src/Registration/login.dart';
import 'package:rent_hive_app/src/Registration/signup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _jumpControllerLogin;
  late AnimationController _jumpControllerSignup;

  late Animation<double> _jumpAnimationLogin;
  late Animation<double> _jumpAnimationSignup;

  late final List<AnimationController> _fadeControllers = [];
  late final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();

    // Jump animation controllers
    _jumpControllerLogin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _jumpControllerSignup = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _jumpAnimationLogin = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _jumpControllerLogin, curve: Curves.easeInOut),
    );

    _jumpAnimationSignup = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _jumpControllerSignup, curve: Curves.easeInOut),
    );

    // Fade animations for widgets appearing one by one
    for (int i = 0; i < 5; i++) {
      AnimationController controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      _fadeControllers.add(controller);
      _fadeAnimations.add(
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn)),
      );
    }

    _startFadeSequence();
  }

  Future<void> _startFadeSequence() async {
    for (int i = 0; i < _fadeControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _fadeControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _jumpControllerLogin.dispose();
    _jumpControllerSignup.dispose();
    for (var c in _fadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Smooth skin tone gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF5E1), // Soft cream
              Color(0xFFFFE8D6), // Light peach
              Color(0xFFFFF0F5), // Very light pinkish
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & App name
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Unique logo (replace Icon with your own widget or Image)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade300,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withAlpha(80),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(15),
                          child: const Icon(
                            Icons.home_work_outlined,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Dancing font app name
                        Text(
                          'RentHive',
                          style: GoogleFonts.dancingScript(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                            shadows: [
                              Shadow(
                                color: Colors.orange.shade200,
                                blurRadius: 15,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Two lines dummy text
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: Column(
                      children: [
                        Text(
                          'Find your perfect home with ease.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.brown.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'RentHive - Where renting feels like home.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.brown.shade300,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Login button jumping animation
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: AnimatedBuilder(
                      animation: _jumpAnimationLogin,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _jumpAnimationLogin.value),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 90,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withAlpha(150),
                                    blurRadius: 15,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Signup button jumping animation
                  FadeTransition(
                    opacity: _fadeAnimations[3],
                    child: AnimatedBuilder(
                      animation: _jumpAnimationSignup,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _jumpAnimationSignup.value),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 80,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.orange.shade400,
                                  width: 3,
                                ),

                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withAlpha(100),
                                    blurRadius: 15,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Signup',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade400,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _fadeAnimations[4],
                    child: Text(
                      'Welcome to RentHive!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.brown.shade300,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
