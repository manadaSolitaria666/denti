// lib/features/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_ai_app/core/providers/auth_provider.dart';
import 'package:dental_ai_app/features/auth/widgets/auth_form_field.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(authNotifierProvider.notifier);
      try {
        if (_isLogin) {
          await notifier.signIn(_emailController.text.trim(), _passwordController.text.trim());
        } else {
          await notifier.signUp(_emailController.text.trim(), _passwordController.text.trim());
        }
        // GoRouter se encargará de la redirección en caso de éxito
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
  
  // Lógica para el botón de Google
  Future<void> _googleSignIn() async {
    try {
      await ref.read(authNotifierProvider.notifier).googleSignIn();
      // GoRouter se encargará de la redirección
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authNotifierProvider);
    final isLoading = authStatus == AuthScreenStatus.loading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                Icon(Icons.medical_services_outlined, size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text("DENTI", textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("CONSULTORIO DENTAL", textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, letterSpacing: 1)),
                const SizedBox(height: 40),

                _buildAuthToggle(theme),
                const SizedBox(height: 24),
                
                AuthFormField(
                  controller: _emailController,
                  labelText: "correo@dominio.com",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty || !val.contains('@')) {
                      return 'Por favor, ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                AuthFormField(
                  controller: _passwordController,
                  labelText: "Contraseña",
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (!_isLogin)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: AuthFormField(
                      controller: _confirmPasswordController,
                      labelText: "Confirmar contraseña",
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isLogin ? "Continuar" : "Crear cuenta"),
                      ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("or", style: TextStyle(color: Colors.grey.shade500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  text: "Continuar con Google",
                  onPressed: isLoading ? null : _googleSignIn, // Conectado
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  text: "Continuar con Apple",
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  onPressed: isLoading ? null : () { /* TODO: Implementar Apple Sign-In */ },
                ),
                const SizedBox(height: 40),

                Text(
                  "Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthToggle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            _formKey.currentState?.reset();
            setState(() => _isLogin = false);
          },
          child: Text(
            "Crea una cuenta",
            style: theme.textTheme.titleMedium?.copyWith(
              color: !_isLogin ? theme.colorScheme.primary : Colors.grey.shade500,
              fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("/", style: TextStyle(color: Colors.grey)),
        ),
        GestureDetector(
          onTap: () {
            _formKey.currentState?.reset();
            setState(() => _isLogin = true);
          },
          child: Text(
            "Iniciar sesión",
            style: theme.textTheme.titleMedium?.copyWith(
              color: _isLogin ? theme.colorScheme.primary : Colors.grey.shade500,
              fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return OutlinedButton.icon(
      icon: FaIcon(icon, size: 20),
      label: Text(text),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: foregroundColor ?? Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
