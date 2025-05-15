// login.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animate_do/animate_do.dart';

// Make sure these paths match your folder structure
import 'create_account.dart'; // Import Create Account page
import 'forget_password.dart'; // Import Forgot Password page

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FirebaseAuth _auth;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Focus nodes for form fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _auth = FirebaseAuth.instance;
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
    
    // Set up focus node listeners
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      // This triggers a rebuild to update UI based on focus
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Add haptic feedback on successful login
      HapticFeedback.mediumImpact();
      
      setState(() {
        _isLoading = false;
      });

      // Show success animation before navigating
      _showSuccessDialog();
      
      // Navigate after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Add haptic feedback on error
      HapticFeedback.vibrate();

      // Show a more user-friendly error message
      String errorMessage = 'Authentication failed. Please check your credentials.';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many attempts. Please try again later.';
        }
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.shade400,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        elevation: 6,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success Dialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Lottie.network(
                'https://assets3.lottiefiles.com/packages/lf20_jbrw3hcz.json',  // Success checkmark animation
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Blurred Background Image with Gradient Overlay
              ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.4),
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/icons/background.png',
                  fit: BoxFit.cover,
                ),
              ),
              
              // Animated gradient overlay - Enhanced for navy blue background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D2149).withOpacity(0.8),  // Darker navy blue
                      Color(0xFF113366).withOpacity(0.6),  // Navy blue
                      Color(0xFF1E4D8C).withOpacity(0.4),  // Lighter navy
                    ],
                  ),
                ),
              ),
              
              // Content with blur effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    height: screenSize.height,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SafeArea(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              
                              // Animated logo at the top
                              Center(
                                child: FadeIn(
                                  duration: const Duration(milliseconds: 1000),
                                  child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/icons/logo.png', // Add your logo here
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 40,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.04),
                              
                              // Welcome text
                              FadeInDown(
                                delay: const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 800),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        height: 1.2, // Improved line height
                                      ),
                                    ),
                                    const SizedBox(height: 8), // More precise spacing
                                    Text(
                                      'Sign in to continue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFFB8C7E0), // Softer blue-tinted white
                                        height: 1.3, // Improved line height
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.06),
                              
                              // Email Input Field with animated label
                              FadeInLeft(
                                delay: const Duration(milliseconds: 400),
                                duration: const Duration(milliseconds: 800),
                                child: _buildInputField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.025),
                              
                              // Password Input Field with animated label and visibility toggle
                              FadeInRight(
                                delay: const Duration(milliseconds: 600),
                                duration: const Duration(milliseconds: 800),
                                child: _buildInputField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              // Forgot Password text
                              Align(
                                alignment: Alignment.centerRight,
                                child: FadeInUp(
                                  delay: const Duration(milliseconds: 700),
                                  duration: const Duration(milliseconds: 800),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => ForgetPasswordPage(),
                                          transitionDuration: const Duration(milliseconds: 500),
                                          transitionsBuilder: (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFFB8C7E0), // Blue-tinted white text
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        height: 1.3, // Improved text alignment
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.04),
                              
                              // Sign In Button with animation
                              FadeInUp(
                                delay: const Duration(milliseconds: 800),
                                duration: const Duration(milliseconds: 800),
                                child: _buildPrimaryButton(
                                  text: 'Sign In',
                                  onPressed: _login,
                                  isLoading: _isLoading,
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.025),
                              
                              // Or continue with text
                              FadeInUp(
                                delay: const Duration(milliseconds: 900),
                                duration: const Duration(milliseconds: 800),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Color(0xFF2C4875), // Mid-tone navy divider
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Or continue with',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Color(0xFFB8C7E0), // Blue-tinted white text
                                          fontWeight: FontWeight.w500,
                                          height: 1.3, // Improved text alignment
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Color(0xFF2C4875), // Mid-tone navy divider
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.025),
                              
                              // Social login options
                              FadeInUp(
                                delay: const Duration(milliseconds: 1000),
                                duration: const Duration(milliseconds: 800),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSocialButton(
                                      icon: 'assets/icons/google.svg',
                                      fallbackIcon: Icons.g_mobiledata_rounded,
                                      onPressed: () {
                                        // Implement Google login
                                        HapticFeedback.lightImpact();
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    _buildSocialButton(
                                      icon: 'assets/icons/apple.svg',
                                      fallbackIcon: Icons.apple_rounded,
                                      onPressed: () {
                                        // Implement Apple login
                                        HapticFeedback.lightImpact();
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    _buildSocialButton(
                                      icon: 'assets/icons/facebook.svg',
                                      fallbackIcon: Icons.facebook_rounded,  
                                      onPressed: () {
                                        // Implement Facebook login
                                        HapticFeedback.lightImpact();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Create account text
                              FadeInUp(
                                delay: const Duration(milliseconds: 1100),
                                duration: const Duration(milliseconds: 800),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (_, __, ___) => CreateAccountPage(),
                                              transitionDuration: const Duration(milliseconds: 500),
                                              transitionsBuilder: (_, animation, __, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Create Account',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final bool isFocused = focusNode.hasFocus;
    
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        height: 1.5, // Improved text alignment
      ),
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isFocused ? Color(0xFFD0DFF9) : Color(0xFFB8C7E0), // Blue-tinted whites for contrast
          fontSize: isFocused ? 14 : 16,
          fontWeight: isFocused ? FontWeight.w500 : FontWeight.normal,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: isFocused ? Color(0xFFD0DFF9) : Color(0xFFB8C7E0), // Matching label color
          size: 22,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: isFocused ? Color(0xFFD0DFF9) : Color(0xFFB8C7E0), // Matching label color
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Color(0xFF0D2555).withOpacity(0.5), // Rich navy for field background
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2C4875).withOpacity(0.5), width: 1.5), // Mid-tone navy border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A7BD1), width: 1.5), // Bright highlight blue border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE57373), width: 1.5), // Softer red for errors
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFEF5350), width: 2), // Bolder error red when focused
        ),
        errorStyle: GoogleFonts.poppins(
          color: Color(0xFFE57373), // Matching error border color
          fontSize: 12,
          height: 1, // Compact error message
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Roomier padding
      ),
      cursorColor: Color(0xFFD0DFF9), // Matching highlighted text color
      onChanged: (text) {
        // You can add character restriction checks here if needed
      },
    );
  }
  
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A7BD1), // Brand blue that complements navy
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Color(0xFF4A7BD1).withOpacity(0.5), // Matching glow
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required String icon,
    required IconData fallbackIcon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      width: 80,
      decoration: BoxDecoration(
        color: Color(0xFF0D2555).withOpacity(0.6), // Rich navy background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF2C4875).withOpacity(0.7), // Mid-tone border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0A1A38).withOpacity(0.3), // Dark navy shadow
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: Color(0xFF4A7BD1).withOpacity(0.2), // Highlight blue splash
          highlightColor: Color(0xFF4A7BD1).withOpacity(0.1), // Highlight blue glow
          child: Center(
            child: SvgPicture.asset(
              icon,
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(Color(0xFFD0DFF9), BlendMode.srcIn), // Blue-tinted white icon
              placeholderBuilder: (BuildContext context) => Icon(
                fallbackIcon,
                size: 24,
                color: Color(0xFFD0DFF9), // Blue-tinted white icon
              ),
            ),
          ),
        ),
      ),
    );
  }
}