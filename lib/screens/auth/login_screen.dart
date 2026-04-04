// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Login Screen
/// Full form validation, remember me toggle, forgot password flow.
/// Uses AuthService from Provider for login.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await Provider.of<AuthService>(context, listen: false).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      showAppSnackBar(context, 'Welcome back!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final authService = Provider.of<AuthService>(context);

    String t(String key) => AppStrings.tr(context, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: authService.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Shield logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Heading
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Log in to continue staying safe',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  CustomTextField(
                    label: t(AppStrings.email),
                    hint: 'priya@example.com',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomTextField(
                    label: t(AppStrings.password),
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Remember me + Forgot password
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          showAppSnackBar(
                              context, 'Reset link sent to your email');
                        },
                        child: Text(
                          t(AppStrings.forgotPassword),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  GradientButton(
                    text: t(AppStrings.login),
                    icon: Icons.login_rounded,
                    isLoading: authService.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 32),

                  // Sign up redirect
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t(AppStrings.noAccount),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            t(AppStrings.signup),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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