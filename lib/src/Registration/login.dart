import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for FirebaseFirestore
//import 'package:rent_hive_app/src/Pages/Home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rent_hive_app/src/Pages/Structure/Structure.dart';
import 'package:rent_hive_app/src/Registration/signup.dart';
import 'package:rent_hive_app/src/admin/adminlogin.dart';
import 'package:rent_hive_app/src/Registration/forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _autoLoginChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedEmail = prefs.getString('email');
    final String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _autoLoginChecked = true;
      });

      // Attempt auto-login
      await _signIn(autoLogin: true);
    } else {
      setState(() {
        _autoLoginChecked = true;
      });
    }
  }

  Future<void> _signIn({bool autoLogin = false}) async {
    if (!autoLogin &&
        (_emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint("Attempting to sign in with email: $email");
    debugPrint("Password length: \\${password.length} characters");

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      debugPrint("Login successful for user: \\${_auth.currentUser?.uid}");

      // Navigate to main screen on successful login
      // Save login credentials if this is a manual login
      if (!autoLogin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (autoLogin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('email');
        await prefs.remove('password');
      }

      debugPrint(
        "Firebase Auth Error during login: Code: \\${e.code}, Message: \\${e.message}",
      );
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided. Please check your password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many failed login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Login failed. Error: ${e.code} - ${e.message}';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      debugPrint("Unexpected error during login: $e");
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add method to check Google Sign-In availability
  Future<bool> _isGoogleSignInAvailable() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final bool isAvailable = await googleSignIn.isSignedIn();
      debugPrint("Google Sign-In available: $isAvailable");
      return true;
    } catch (e) {
      debugPrint("Google Sign-In not available: $e");
      return false;
    }
  }

  // Add method to check Google Play Services
  Future<bool> _checkGooglePlayServices() async {
    try {
      // This is a simple check - in a real app you might want to use GoogleApiAvailability
      return true;
    } catch (e) {
      debugPrint("Google Play Services check failed: $e");
      return false;
    }
  }

  // Add method to handle Google Play Services update
  void _showGooglePlayServicesUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Required'),
            content: const Text(
              'Google Play Services needs to be updated for Google Sign-In to work properly.\n\n'
              'Please update Google Play Services from the Play Store and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("Starting Google Sign-In process...");

      // Check if Google Play Services are available
      final bool playServicesAvailable = await _checkGooglePlayServices();
      if (!playServicesAvailable) {
        _showErrorDialog(
          'Google Play Services are not available. Please update Google Play Services and try again.',
        );
        return;
      }

      // Check if Google Sign-In is available
      final bool isAvailable = await _isGoogleSignInAvailable();
      if (!isAvailable) {
        _showErrorDialog(
          'Google Sign-In is not available. Please make sure you have:\n\n1. Updated Google Play Services\n2. Added a Google account to your device\n3. Have an active internet connection',
        );
        return;
      }

      // Initialize Google Sign-In with specific configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Add client ID if needed
        // clientId: 'your-client-id.apps.googleusercontent.com',
      );

      // Check if user is already signed in
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      if (currentUser != null) {
        debugPrint("User already signed in: ${currentUser.email}");
        await googleSignIn
            .signOut(); // Sign out first to allow re-authentication
      }

      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("User cancelled Google Sign-In");
        setState(() {
          _isLoading = false;
        });
        return; // User cancelled the sign-in
      }

      debugPrint("Google Sign-In successful for: ${googleUser.email}");

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("Got authentication tokens");
      debugPrint(
        "Access token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}",
      );
      debugPrint(
        "ID token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}",
      );

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("Created Firebase credential");

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint("Firebase authentication successful");
      debugPrint("User ID: ${userCredential.user?.uid}");
      debugPrint("User email: ${userCredential.user?.email}");

      // Check if user exists in Firestore, if not create user document
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        debugPrint("Creating new user document in Firestore");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'name': userCredential.user!.displayName ?? 'User',
              'email': userCredential.user!.email,
              'photoURL': userCredential.user!.photoURL,
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
              'isActive': true,
              'profileCompleted': true,
              'signInMethod': 'google',
            });
        debugPrint("User document created successfully");
      } else {
        debugPrint("User document already exists");
      }

      // Navigate to main screen on successful login
      if (mounted) {
        debugPrint("Navigating to main screen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Exception: ${e.code} - ${e.message}");
      String errorMessage;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Google Sign-In is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with these credentials.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Google sign-in failed: ${e.message}';
      }

      _showErrorDialog(errorMessage);
    } catch (e) {
      debugPrint("Unexpected error during Google Sign-In: $e");

      // Check for specific Google Play Services errors
      if (e.toString().contains('SERVICE_VERSION_UPDATE_REQUIRED') ||
          e.toString().contains('Google Play services out of date') ||
          e.toString().contains('12451000')) {
        _showGooglePlayServicesUpdateDialog();
      } else {
        _showErrorDialog(
          'An unexpected error occurred during Google Sign-In. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to clear saved credentials when logging out
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    debugPrint("Password validation:");
    debugPrint("- Length: \\${password.length} characters");
    debugPrint(
      "- Contains uppercase: \\${password.contains(RegExp(r'[A-Z]'))}",
    );
    debugPrint(
      "- Contains lowercase: \\${password.contains(RegExp(r'[a-z]'))}",
    );
    debugPrint("- Contains numbers: \\${password.contains(RegExp(r'[0-9]'))}");
    debugPrint(
      "- Contains special chars: \\${password.contains(RegExp(r'[!@#\$%^&*(),.?\":{}|<>]'))}",
    );

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters long');
    } else {
      _showSuccessDialog('Password format looks good!');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking for auto-login
    if (!_autoLoginChecked) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 400,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1200),
                        child: Center(
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: SvgPicture.asset(
                              "assets/Images/shopping.svg",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      top: 80,
                      left: 0,
                      right: 0,
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1600),
                        child: Text(
                          "Login In",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  children: <Widget>[
                    FadeInUp(
                      duration: Duration(milliseconds: 1800),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Color.fromRGBO(143, 148, 251, 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(143, 148, 251, .2),
                              blurRadius: 20.0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    icon: Icon(
                                      Icons.email,
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                    ),
                                    border: InputBorder.none,
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    icon: Icon(
                                      Icons.lock,
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Color.fromRGBO(
                                              143,
                                              148,
                                              251,
                                              1,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.info_outline,
                                            color: Color.fromRGBO(
                                              143,
                                              148,
                                              251,
                                              1,
                                            ),
                                          ),
                                          onPressed: _validatePassword,
                                          tooltip: 'Validate Password',
                                        ),
                                      ],
                                    ),
                                    border: InputBorder.none,
                                    hintText: "Password",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    FadeInUp(
                      duration: Duration(milliseconds: 1900),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(143, 148, 251, 1),
                              Color.fromRGBO(143, 148, 251, .6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _signIn,
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                    : Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    FadeInUp(
                      duration: Duration(milliseconds: 2000),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.login,
                                  color: Colors.red,
                                  size: 24,
                                ),
                          ),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'Sign in with Google',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FadeInUp(
                      duration: Duration(milliseconds: 2000),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Color.fromRGBO(143, 148, 251, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    FadeInUp(
                      duration: Duration(milliseconds: 2000),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color.fromRGBO(143, 148, 251, 1),
                          ),
                        ),
                      ),
                    ),
                    FadeInUp(
                      duration: Duration(milliseconds: 2000),
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.deepPurple,
                        ),
                        label: Text(
                          'Admin Login',
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginPage(),
                            ),
                          );
                        },
                      ),
                    ),
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
