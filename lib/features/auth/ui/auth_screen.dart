import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_text_field.dart';
import '../providers/auth_provider.dart';

/// AuthScreen - Login and signup
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSuccess = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _nameError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
      _emailError = null;
      _passwordError = null;
      _nameError = null;
    });

    // Basic validation
    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (!_isLogin && name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      hasError = true;
    }

    if (hasError) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isLogin) {
        await ref.read(authStateProvider.notifier).signIn(email, password);
      } else {
        await ref
            .read(authStateProvider.notifier)
            .signUp(email, password, name);
      }

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        // brief delay to show green button
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            message = 'Invalid email or password.';
            setState(() {
              _emailError = '';
              _passwordError = '';
            });
            break;
          case 'email-already-in-use':
            message = 'This email is already in use.';
            setState(() => _emailError = message);
            break;
          case 'weak-password':
            message = 'Password is too weak.';
            setState(() => _passwordError = message);
            break;
          case 'invalid-email':
            message = 'Invalid email address.';
            setState(() => _emailError = message);
            break;
          default:
            message = e.message ?? 'An error occurred. Please try again.';
        }
        setState(() => _error = message);
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = 'An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted && !_isSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: AnimatedScale(
          scale: _isSuccess ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _isSuccess ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Text(
                    'NeetFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Welcome back!' : 'Create your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: context.textSecondaryColor,
                    ),
                  ),

                  const SizedBox(height: 40),

                  AppCard(
                    child: Column(
                      children: [
                        // Error message
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: context.errorBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: context.errorColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.alertCircle,
                                    color: context.errorColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                        color: context.errorColor,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Name field (signup only)
                        if (!_isLogin) ...[
                          AppTextField(
                            label: 'Name',
                            controller: _nameController,
                            prefixIcon: LucideIcons.user,
                            textInputAction: TextInputAction.next,
                            errorText: _nameError,
                            onChanged: (_) {
                              if (_nameError != null) {
                                setState(() => _nameError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        AppTextField(
                          label: 'Email',
                          controller: _emailController,
                          prefixIcon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        AppTextField(
                          label: 'Password',
                          controller: _passwordController,
                          prefixIcon: LucideIcons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              size: 20,
                              color: context.iconColor,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSubmit(),
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: AppButton(
                              text: _isSuccess
                                  ? 'Success!'
                                  : (_isLogin ? 'Sign In' : 'Create Account'),
                              isLoading: _isLoading,
                              backgroundColor: _isSuccess ? Colors.green : null,
                              icon: _isSuccess ? LucideIcons.check : null,
                              onPressed: _isSuccess ? null : _handleSubmit,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle login/signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                            _emailController.clear();
                            _passwordController.clear();
                            _nameController.clear();
                          });
                        },
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
