import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart' as emailjs;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Remove any non-digit characters for validation
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    if (!RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists
      bool emailExists = await _checkEmailExists(_emailController.text.trim());
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An account with this email already exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );

      // Update user profile with display name
      await credential.user!.updateDisplayName(_nameController.text.trim());

      // Store additional user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'isActive': true,
            'profileCompleted': true,
          });

      // Send email verification
      await credential.user!.sendEmailVerification();

      try {
        await emailjs.send(
          dotenv.env['EMAIL_SERVICE'] ?? '',
          dotenv.env['EMAIL_TEMPLATE'] ?? '',
          {
            'user_name': _nameController.text.trim(),
            'user_email': _emailController.text.trim(),
          },
          emailjs.Options(
            publicKey: dotenv.env['PUBLIC_KEY'] ?? '',
            privateKey: dotenv.env['PRIVATE_KEY'] ?? '',
          ),
        );
      } catch (emailJsError) {
        print('Failed to send welcome email: $emailJsError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Please verify your email.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate back to login page
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during signup';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasVisibilityToggle = false,
    VoidCallback? onVisibilityToggle,
    bool showVisibility = false,
    TextInputType keyboardType = TextInputType.text,
    bool isLastField = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border:
            isLastField
                ? null
                : const Border(
                  bottom: BorderSide(color: Color.fromRGBO(143, 148, 251, 1)),
                ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization:
            hintText == 'Full Name'
                ? TextCapitalization.words
                : TextCapitalization.none,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color.fromRGBO(143, 148, 251, 1)),
          suffixIcon:
              hasVisibilityToggle
                  ? IconButton(
                    icon: Icon(
                      showVisibility ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromRGBO(143, 148, 251, 1),
                    ),
                    onPressed: onVisibilityToggle,
                  )
                  : null,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 350,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    right: 100,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: SvgPicture.asset(
                            "assets/Images/shopping.svg",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1800),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromRGBO(143, 148, 251, 1),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(143, 148, 251, .2),
                            blurRadius: 20.0,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            _buildTextFormField(
                              controller: _nameController,
                              hintText: 'Full Name',
                              icon: Icons.person,
                              validator: _validateName,
                              keyboardType: TextInputType.name,
                            ),
                            _buildTextFormField(
                              controller: _emailController,
                              hintText: 'Email',
                              icon: Icons.email,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildTextFormField(
                              controller: _phoneController,
                              hintText: 'Phone Number',
                              icon: Icons.phone,
                              validator: _validatePhone,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextFormField(
                              controller: _passController,
                              hintText: 'Password',
                              icon: Icons.lock,
                              validator: _validatePassword,
                              obscureText: _obscurePassword,
                              hasVisibilityToggle: true,
                              showVisibility: _obscurePassword,
                              onVisibilityToggle: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            _buildTextFormField(
                              controller: _confirmPassController,
                              hintText: 'Confirm Password',
                              icon: Icons.lock_outline,
                              validator: _validateConfirmPassword,
                              obscureText: _obscureConfirmPassword,
                              hasVisibilityToggle: true,
                              showVisibility: _obscureConfirmPassword,
                              onVisibilityToggle: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              isLastField: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password requirements info
                  FadeInUp(
                    duration: const Duration(milliseconds: 1850),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number\n• One special character',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1900),
                    child: GestureDetector(
                      onTap: _isLoading ? null : _signupUser,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors:
                                _isLoading
                                    ? [Colors.grey[400]!, Colors.grey[300]!]
                                    : [
                                      const Color.fromRGBO(143, 148, 251, 1),
                                      const Color.fromRGBO(143, 148, 251, .6),
                                    ],
                          ),
                        ),
                        child: Center(
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 2000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Color.fromRGBO(143, 148, 251, 1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
