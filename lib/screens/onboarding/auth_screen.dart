import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showForm = false;
  bool _isSignIn = false;
  bool _loading = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final service = ref.read(authServiceProvider);
      if (_isSignIn) {
        await service.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await service.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }
      if (!mounted) return;
      context.go('/pair');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LoveSnapsColors.background,
              LoveSnapsColors.primaryContainer,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative Blobs
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.primaryContainer.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 4.seconds,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
              ),
            ),
            Positioned(
              top: -40,
              left: -40,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(width: 256, height: 256),
              ),
            ),
            
            Positioned(
              bottom: -40,
              right: -40,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.secondaryContainer.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 5.seconds,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
              ),
            ),
            Positioned(
              bottom: -40,
              right: -40,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(width: 320, height: 320),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 192,
                        fit: BoxFit.contain,
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                        begin: -10,
                        end: 10,
                        duration: 3.seconds,
                        curve: Curves.easeInOut,
                      ),
                      
                      const SizedBox(height: 40),

                      if (!_showForm) ...[
                        // Illustration Canvas
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                                boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Inner gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                        colors: [
                                          LoveSnapsColors.primaryContainer.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Hearts image
                                  ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Image.asset(
                                        'assets/images/hearts.png',
                                        width: 250,
                                        height: 250,
                                        fit: BoxFit.contain,
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                        begin: const Offset(0.95, 0.95),
                                        end: const Offset(1.05, 1.05),
                                        duration: 4.seconds,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut),

                        const SizedBox(height: 40),

                        // Text & Actions
                        Text(
                          "Let's get you two connected 💫",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: LoveSnapsColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          "Create a cozy space for just the two of you to share moments, memories, and little surprises.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LoveSnapsColors.onSurfaceVariant.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 40),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showForm = true;
                                _isSignIn = false;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Get Started"),
                                const SizedBox(width: 8),
                                const Icon(Icons.favorite, size: 24),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

                        const SizedBox(height: 24),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showForm = true;
                              _isSignIn = true;
                            });
                          },
                          child: Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: LoveSnapsColors.onSurfaceVariant.withOpacity(0.6),
                              ),
                              children: [
                                TextSpan(
                                  text: "Log in",
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: LoveSnapsColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                      ] else ...[
                        // Form View
                        _buildForm(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      children: [
        Text(
          _isSignIn ? 'Welcome back' : 'Create account',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignIn
              ? 'Sign in to connect with your partner'
              : 'Start your love story today',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LoveSnapsColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isSignIn) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Please enter a valid email'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: !_obscurePassword,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _obscurePassword = !v;
                          });
                        }
                      },
                      activeColor: LoveSnapsColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Text(
                      'Show Password',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LoveSnapsColors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LoveSnapsColors.errorContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LoveSnapsColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: LoveSnapsColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: LoveSnapsColors.onErrorContainer),
                  ),
                ),
              ],
            ),
          ).animate().shake(duration: 400.ms),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LoveSnapsColors.onTertiaryContainer,
                  ),
                )
              : Text(_isSignIn ? 'Sign In' : 'Create Account'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignIn = !_isSignIn;
              _error = null;
            });
          },
          child: Text.rich(
            TextSpan(
              text: _isSignIn
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: TextStyle(color: LoveSnapsColors.onSurfaceVariant),
              children: [
                TextSpan(
                  text: _isSignIn ? 'Sign up' : 'Sign in',
                  style: const TextStyle(
                    color: LoveSnapsColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _showForm = false;
              _error = null;
            });
          },
          child: const Text("Back"),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
