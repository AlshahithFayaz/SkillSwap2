import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'skill_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedDept = 'AI&DS';
  String _selectedYear = '3rd';
  bool _obscurePassword = true;

  final List<String> _departments = [
    'AI&DS',
    'CSE',
    'IT',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'Other',
  ];

  final List<String> _years = ['1st', '2nd', '3rd', '4th'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      rollNo: _rollNoController.text.trim(),
      department: _selectedDept,
      year: _selectedYear,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SkillOnboardingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join SkillSwap',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Trade knowledge with students across departments',
                  style: AppTextStyles.bodyMediumSecondary,
                ),
                const SizedBox(height: 24),

                // Full Name
                Text('Full Name', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // College Email
                Text('College Email', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'student@college.edu',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'College email is required';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Roll Number
                Text('Roll Number', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rollNoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 21AD045',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Roll number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Department & Year row
                Row(
                  children: [
                    // Department
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Department', style: AppTextStyles.subheading),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDept,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: _departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept,
                                child: Text(dept, style: AppTextStyles.body),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDept = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Year
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Year', style: AppTextStyles.subheading),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedYear,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: _years.map((yr) {
                              return DropdownMenuItem(
                                value: yr,
                                child: Text(yr, style: AppTextStyles.body),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password
                Text('Password', style: AppTextStyles.subheading),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Create Account & Continue',
                  onPressed: _handleRegister,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
