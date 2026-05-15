import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../domain/user_profile.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _collegeDepartmentController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  String _availabilityStatus = 'available';
  String? _loadedUid;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _collegeDepartmentController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;

    if (profile != null && _loadedUid != profile.uid) {
      _syncControllers(profile);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Save profile',
            onPressed: controller.isSaving || controller.isLoading
                ? null
                : _saveProfile,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.errorMessage != null) ...[
                        AuthErrorBanner(
                          message: controller.errorMessage!,
                          onDismissed: controller.clearError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _ProfileHeader(profile: profile),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _required('Full name'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: _required('Student ID'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _collegeDepartmentController,
                        decoration: const InputDecoration(
                          labelText: 'College/Department',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        validator: _required('College/Department'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: _required('Username'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Bio/About',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          labelText: 'Skills/categories',
                          hintText: 'Portraits, logos, character art',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _availabilityStatus,
                        decoration: const InputDecoration(
                          labelText: 'Availability status',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(value: 'busy', child: Text('Busy')),
                          DropdownMenuItem(
                            value: 'unavailable',
                            child: Text('Unavailable'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _availabilityStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: controller.isSaving ? null : _saveProfile,
                        icon: controller.isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save profile'),
                      ),
                      const SizedBox(height: 16),
                      const _PortfolioPlaceholder(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _syncControllers(UserProfile profile) {
    _loadedUid = profile.uid;
    _fullNameController.text = profile.fullName;
    _studentIdController.text = profile.studentId;
    _collegeDepartmentController.text = profile.collegeDepartment;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio;
    _skillsController.text = profile.skills.join(', ');
    _availabilityStatus = profile.availabilityStatus;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<ProfileController>();
    final profile = controller.profile;
    if (profile == null) {
      return;
    }

    final saved = await controller.saveProfile(
      UserProfile(
        uid: profile.uid,
        profilePictureUrl: profile.profilePictureUrl,
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        collegeDepartment: _collegeDepartmentController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skillsController.text
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList(),
        portfolioGallery: profile.portfolioGallery,
        availabilityStatus: _availabilityStatus,
      ),
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    }
  }

  String? Function(String?) _required(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required.';
      }
      return null;
    };
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: profile?.profilePictureUrl.isNotEmpty == true
              ? NetworkImage(profile!.profilePictureUrl)
              : null,
          child: profile?.profilePictureUrl.isNotEmpty == true
              ? null
              : Icon(
                  Icons.person_outline,
                  color: colorScheme.onPrimaryContainer,
                  size: 40,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'Your profile',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                profile?.collegeDepartment.isNotEmpty == true
                    ? profile!.collegeDepartment
                    : 'Add your department',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.photo_library_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text('Portfolio gallery upload will be added next.'),
            ),
          ],
        ),
      ),
    );
  }
}
