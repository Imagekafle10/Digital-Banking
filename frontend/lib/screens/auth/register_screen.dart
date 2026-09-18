import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/root_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  bool _isLoading = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            dateOfBirth: _dob!,
            gender: _gender!,
          );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 56,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Join in a minute',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set up your login - you can open a bank account right after.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                CustomTextField(
                  label: 'Full name',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.mail_outline_rounded,
                        autofillHints: const [
                          AutofillHints.newUsername,
                          AutofillHints.email,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!value.contains('@'))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        icon: Icons.lock_outline_rounded,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'At least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        icon: Icons.lock_outline_rounded,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Date of birth',
                      controller: _dobController,
                      icon: Icons.cake_outlined,
                      validator: (_) {
                        if (_dob == null) return 'Select your date of birth';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.people_alt_outlined),
                  ),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (value) {
                    if (value == null) return 'Select your gender';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your phone number';
                    }
                    if (value.trim().length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
