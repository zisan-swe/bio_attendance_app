import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/company_settings_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _emailNode = FocusNode();
  final _passNode = FocusNode();

  String errorMessage = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure company settings are loaded at least once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<CompanySettingsProvider>();
      if (prov.setting == null && !prov.isLoading) {
        prov.load();
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    super.dispose();
  }

  /// Login method
  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    final success = await auth.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  HomeScreen()),
      );
    } else {
      setState(() => errorMessage = 'Invalid email or password.');
    }
  }

  /// Header widget (uses dynamic company name)
  Widget _buildHeader({required String title, required bool isLoading}) {
    return Column(
      children: [
        // App / company logo
        Image.asset(
          'assets/logo.jpeg',
          height: 100,
        ),
        const SizedBox(height: 16),
        // You can keep or remove the fingerprint icon
        // Icon(Icons.fingerprint, size: 80, color: Colors.blueAccent),
        // SizedBox(height: 16),


        // Dynamic title from company_settings
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
            key: ValueKey('title-loading'),
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : Text(
            title,
            key: const ValueKey('title-ready'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          'Login to continue',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// TextField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSubmitted,
    bool obscureText = false,
    IconData? icon,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: action,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: onToggleVisibility != null
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyProv = context.watch<CompanySettingsProvider>();
    final isCompanyLoading = companyProv.isLoading;
    final companyName = (companyProv.setting?.companyName.trim().isNotEmpty ?? false)
        ? companyProv.setting!.companyName
        : 'KISAN BOTANIX'; // fallback if no row yet

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(title: companyName, isLoading: isCompanyLoading),

                    // Error message
                    if (errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email
                    _buildTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email,
                      focusNode: _emailNode,
                      action: TextInputAction.next,
                      onSubmitted: (_) => _passNode.requestFocus(),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildTextField(
                      controller: passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      icon: Icons.lock,
                      onToggleVisibility: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                      focusNode: _passNode,
                      action: TextInputAction.done,
                      onSubmitted: (_) => _isLoading ? null : _login(),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.login),
                        label: Text(
                          _isLoading ? 'Logging in...' : 'Login',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
