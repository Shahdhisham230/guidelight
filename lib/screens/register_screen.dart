import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _parentEmailController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Default role
  String _selectedRole = 'parent';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parentEmailController.dispose();

    super.dispose();
  }

  // =========================
  // REGISTER
  // =========================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
        _selectedRole == 'family_member'
            ? _parentEmailController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully! ✅',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // =========================
                  // ICON
                  // =========================

                  const Icon(
                    Icons.person_add,
                    size: 80,
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // TITLE
                  // =========================

                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create your family account',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =========================
                  // USERNAME
                  // =========================

                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your username';
                      }

                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // EMAIL
                  // =========================

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // PASSWORD
                  // =========================

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // ROLE TITLE
                  // =========================

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'I am:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =========================
                  // PARENT
                  // =========================

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedRole == 'parent'
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.grey.shade300,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: RadioListTile<String>(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),

                      title: const Text(
                        'Parent',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        'Monitor and manage family members',
                      ),

                      value: 'parent',

                      groupValue: _selectedRole,

                      onChanged: _isLoading
                          ? null
                          : (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedRole = value;
                                _parentEmailController
                                    .clear();
                              });
                            },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // FAMILY MEMBER
                  // =========================

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _selectedRole ==
                                    'family_member'
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                : Colors.grey.shade300,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: RadioListTile<String>(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),

                      title: const Text(
                        'Family Member',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        'Share your location and request help',
                      ),

                      value: 'family_member',

                      groupValue: _selectedRole,

                      onChanged: _isLoading
                          ? null
                          : (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedRole = value;
                              });
                            },
                    ),
                  ),

                  // =========================
                  // PARENT EMAIL
                  // =========================

                  if (_selectedRole == 'family_member') ...[
                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _parentEmailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          const InputDecoration(
                        labelText: 'Parent Email',
                        hintText:
                            'Enter your parent email',
                        helperText:
                            'Enter the email of the parent account',
                        prefixIcon: Icon(
                          Icons.family_restroom,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedRole !=
                            'family_member') {
                          return null;
                        }

                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your parent email';
                        }

                        if (!value.contains('@')) {
                          return 'Please enter a valid parent email';
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 28),

                  // =========================
                  // CREATE ACCOUNT
                  // =========================

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _register,

                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // LOGIN
                  // =========================

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Already have an account? Login',
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}