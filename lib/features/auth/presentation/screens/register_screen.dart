import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _colleges = <String>[
    'College of Education (COE)',
    'College of Arts & Sciences (CAS)',
    'College of Management & Entrepreneurship (CME)',
  ];

  static const _programsByCollege = <String, List<String>>{
    'College of Education (COE)': [
      'Bachelor of Elementary Education (BEED)',
      'Bachelor of Early Childhood Education (BECEd)',
      'Bachelor of Special Needs Education (BSNEd) - Generalist',
      'Bachelor of Technology and Livelihood Education (BTLEd) - Major in Home Economics',
      'Bachelor of Secondary Education (BSED)',
      'Bachelor of Physical Education (BPEd)',
      'Teacher Certificate Program (TCP)',
    ],
    'College of Arts & Sciences (CAS)': [
      'Bachelor of Arts in English Language (BAEL)',
      'Bachelor of Arts in Communication (BAComm)',
      'Bachelor of Arts in Political Science (BAPoS)',
      'Bachelor of Science in Social Work (BSSW)',
      'Bachelor of Science in Information Technology (BSIT)',
      'Bachelor of Science in Biology (BSBIo)',
      'Bachelor of Library and Information Science (BLIS)',
      'Bachelor of Music in Music Education (BMME)',
    ],
    'College of Management & Entrepreneurship (CME)': [
      'Bachelor of Science in Tourism Management (BSTM)',
      'Bachelor of Science in Hospitality Management (BSHM)',
      'Bachelor of Science in Entrepreneurship (BSEntrep)',
    ],
  };

  static const _yearLevels = <String>['1st', '2nd', '3rd', '4th'];

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedCollege;
  String? _selectedProgram;
  String? _selectedYearLevel;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_capitalizeFullName);
    _studentIdController.addListener(_syncEmailWithStudentId);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_capitalizeFullName);
    _studentIdController.removeListener(_syncEmailWithStudentId);
    _fullNameController.dispose();
    _studentIdController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _yearLevelController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AuthShell(
      title: 'Create Account',
      subtitle: 'Use your LNU email to register.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authController.errorMessage != null) ...[
              AuthErrorBanner(
                message: authController.errorMessage!,
                onDismissed: authController.clearError,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) =>
                  AuthValidators.requiredText(value, 'Full name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: AuthValidators.username,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) =>
                  AuthValidators.requiredText(value, 'Student ID'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCollege,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'College',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
              items: _colleges
                  .map(
                    (college) =>
                        DropdownMenuItem(value: college, child: Text(college)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollege = value;
                  _selectedProgram = null;
                  _collegeController.text = value ?? '';
                  _departmentController.clear();
                });
              },
              validator: (value) =>
                  AuthValidators.requiredText(value, 'College'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCollege),
              initialValue: _selectedProgram,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Program',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              items: (_programsByCollege[_selectedCollege] ?? const <String>[])
                  .map(
                    (program) =>
                        DropdownMenuItem(value: program, child: Text(program)),
                  )
                  .toList(),
              onChanged: _selectedCollege == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedProgram = value;
                        _departmentController.text = value ?? '';
                      });
                    },
              validator: (value) =>
                  AuthValidators.requiredText(value, 'Program'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedYearLevel,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Year level',
                prefixIcon: Icon(Icons.stacked_line_chart_outlined),
              ),
              items: _yearLevels
                  .map(
                    (yearLevel) => DropdownMenuItem(
                      value: yearLevel,
                      child: Text(yearLevel),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedYearLevel = value;
                  _yearLevelController.text = value ?? '';
                });
              },
              validator: (value) =>
                  AuthValidators.requiredText(value, 'Year level'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: AuthValidators.lnuEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final passwordError = AuthValidators.password(value);
                if (passwordError != null) {
                  return passwordError;
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authController.isBusy ? null : _submit,
              child: authController.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: authController.isBusy
                  ? null
                  : () => context.go('/login'),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text;
    final didRegister = await authController.register(
      fullName: _titleCaseFullName(_fullNameController.text),
      studentId: _studentIdController.text,
      college: _collegeController.text,
      department: _departmentController.text,
      yearLevel: _yearLevelController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !didRegister) {
      return;
    }

    await authController.signOut();
    if (!mounted) {
      return;
    }

    context.go('/login');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful. Verification link sent to $email.',
          ),
        ),
      );
  }

  void _syncEmailWithStudentId() {
    final studentId = _studentIdController.text.trim();
    final email = studentId.isEmpty ? '' : '$studentId@lnu.edu.ph';
    if (_emailController.text == email) {
      return;
    }
    _emailController.text = email;
  }

  void _capitalizeFullName() {
    final formattedName = _titleCaseFullName(_fullNameController.text);
    if (_fullNameController.text == formattedName) {
      return;
    }
    _fullNameController.value = _fullNameController.value.copyWith(
      text: formattedName,
      selection: TextSelection.collapsed(offset: formattedName.length),
      composing: TextRange.empty,
    );
  }

  String _titleCaseFullName(String value) {
    final lowerValue = value.toLowerCase();
    final buffer = StringBuffer();
    var capitalizeNext = true;

    for (final codeUnit in lowerValue.codeUnits) {
      final character = String.fromCharCode(codeUnit);
      if (RegExp(r'[a-z]').hasMatch(character) && capitalizeNext) {
        buffer.write(character.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(character);
        capitalizeNext = RegExp(r'[\s-]').hasMatch(character);
      }
    }

    return buffer.toString();
  }
}
