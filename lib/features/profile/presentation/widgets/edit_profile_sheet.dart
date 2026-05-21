import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final StudentProfile profile;
  final ValueChanged<StudentProfile> onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const _yearLevels = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
    'Student',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _collegeController;
  late final TextEditingController _departmentController;
  late final TextEditingController _skillsController;
  late String _yearLevel;
  late AvailabilityStatus _availability;
  late VisibilityType _visibility;
  late final List<String> _safeYearLevels;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _bioController = TextEditingController(text: widget.profile.bio);
    _collegeController = TextEditingController(text: widget.profile.college);
    _departmentController = TextEditingController(
      text: widget.profile.department,
    );
    _skillsController = TextEditingController(
      text: widget.profile.skills.join(', '),
    );
    final incomingYear = widget.profile.yearLevel.trim();
    _safeYearLevels = {
      ..._yearLevels,
      if (incomingYear.isNotEmpty) incomingYear,
    }.toList(growable: false);
    _yearLevel = _safeYearLevels.contains(incomingYear)
        ? incomingYear
        : 'Student';
    _availability = widget.profile.availability;
    _visibility = widget.profile.visibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: SkillHubProfileColors.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('edit-profile-name'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final college = TextField(
                    controller: _collegeController,
                    decoration: const InputDecoration(labelText: 'College'),
                  );
                  final department = TextField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  );
                  if (compact) {
                    return Column(
                      children: [
                        college,
                        const SizedBox(height: 12),
                        department,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: college),
                      const SizedBox(width: 12),
                      Expanded(child: department),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _yearLevel,
                decoration: const InputDecoration(labelText: 'Year level'),
                items: _safeYearLevels
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _yearLevel = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  hintText: 'Digital Art, Logo Design, Poster Layout',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AvailabilityStatus>(
                initialValue: _availability,
                decoration: const InputDecoration(
                  labelText: 'Commission availability',
                ),
                items: AvailabilityStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _availability = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VisibilityType>(
                initialValue: _visibility,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Profile visibility',
                ),
                selectedItemBuilder: (context) {
                  return VisibilityType.values
                      .map(
                        (visibility) => Text(
                          visibility.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                      .toList();
                },
                items: VisibilityType.values
                    .map(
                      (visibility) => DropdownMenuItem(
                        value: visibility,
                        child: Text(
                          '${visibility.label} - ${visibility.description}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _visibility = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              const _VisibilityNote(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: SkillHubProfileColors.navy,
                        foregroundColor: SkillHubProfileColors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 17),
                      label: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final skills = _skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);

    widget.onSave(
      widget.profile.copyWith(
        fullName: _nameController.text.trim().isEmpty
            ? widget.profile.fullName
            : _nameController.text.trim(),
        bio: _bioController.text.trim(),
        college: _collegeController.text.trim(),
        department: _departmentController.text.trim(),
        yearLevel: _yearLevel,
        skills: skills,
        availability: _availability,
        visibility: _visibility,
      ),
    );
    Navigator.of(context).pop();
  }
}

class _VisibilityNote extends StatelessWidget {
  const _VisibilityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF003566)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: SkillHubProfileColors.navy, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your profile is only visible to other verified LNU SkillHub students. External access is not permitted on this platform.',
              style: TextStyle(
                color: SkillHubProfileColors.midBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
