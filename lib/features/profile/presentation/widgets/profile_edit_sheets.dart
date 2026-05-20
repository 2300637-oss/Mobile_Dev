import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class EditPostSheet extends StatefulWidget {
  const EditPostSheet({super.key, required this.post, required this.onSave});

  final ProfilePost post;
  final Future<void> Function(ProfilePost post) onSave;

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late final TextEditingController _contentController;
  late VisibilityType _visibility;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _visibility = widget.post.visibility;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: 'Edit Post',
      children: [
        TextField(
          controller: _contentController,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Post content',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<VisibilityType>(
          initialValue: _visibility,
          decoration: const InputDecoration(
            labelText: 'Audience',
            border: OutlineInputBorder(),
          ),
          items: VisibilityType.values
              .map(
                (visibility) => DropdownMenuItem(
                  value: visibility,
                  child: Text(
                    '${visibility.label} - ${visibility.description}',
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
        const SizedBox(height: 8),
        const Text(
          'Attachment editing is not wired yet. Existing attachments are kept as-is.',
          style: TextStyle(color: SkillHubProfileColors.textSub, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _SheetActions(
          primaryLabel: 'Save Post',
          onPrimary: () async {
            final content = _contentController.text.trim();
            if (content.isEmpty) {
              return;
            }
            final navigator = Navigator.of(context);
            await widget.onSave(
              widget.post.copyWith(content: content, visibility: _visibility),
            );
            if (mounted) {
              navigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class AudienceSheet extends StatelessWidget {
  const AudienceSheet({super.key, required this.selected});

  final VisibilityType selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Audience', style: profileSectionTitleStyle()),
            const SizedBox(height: 10),
            for (final visibility in VisibilityType.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_visibilityIcon(visibility)),
                title: Text(visibility.label),
                subtitle: Text(visibility.description),
                trailing: visibility == selected
                    ? const Icon(Icons.check, color: SkillHubProfileColors.navy)
                    : null,
                onTap: () => Navigator.of(context).pop(visibility),
              ),
          ],
        ),
      ),
    );
  }
}

class ServiceEditSheet extends StatefulWidget {
  const ServiceEditSheet({
    super.key,
    required this.service,
    required this.profileId,
    required this.onSave,
  });

  final ProfileService? service;
  final String profileId;
  final Future<void> Function(ProfileService service) onSave;

  @override
  State<ServiceEditSheet> createState() => _ServiceEditSheetState();
}

class _ServiceEditSheetState extends State<ServiceEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _deliveryController;
  late AvailabilityStatus _availability;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _titleController = TextEditingController(text: service?.title ?? '');
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _categoryController = TextEditingController(text: service?.category ?? '');
    _priceController = TextEditingController(text: service?.priceRange ?? '');
    _deliveryController = TextEditingController(
      text: service?.deliveryTime ?? '',
    );
    _availability = service?.availability ?? AvailabilityStatus.open;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: widget.service == null ? 'Add Service' : 'Edit Service',
      children: [
        _TextInput(label: 'Title', controller: _titleController),
        _TextInput(
          label: 'Description',
          controller: _descriptionController,
          minLines: 3,
        ),
        _TextInput(label: 'Category', controller: _categoryController),
        _TextInput(label: 'Price range', controller: _priceController),
        _TextInput(label: 'Delivery time', controller: _deliveryController),
        DropdownButtonFormField<AvailabilityStatus>(
          initialValue: _availability,
          decoration: const InputDecoration(
            labelText: 'Availability',
            border: OutlineInputBorder(),
          ),
          items: AvailabilityStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _availability = value);
            }
          },
        ),
        const SizedBox(height: 16),
        _SheetActions(
          primaryLabel: 'Save Service',
          onPrimary: () async {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            final service = ProfileService(
              id: widget.service?.id ?? '',
              profileId: widget.service?.profileId ?? widget.profileId,
              title: title,
              description: _descriptionController.text.trim(),
              category: _categoryController.text.trim().isEmpty
                  ? 'General'
                  : _categoryController.text.trim(),
              priceRange: _priceController.text.trim(),
              deliveryTime: _deliveryController.text.trim(),
              availability: _availability,
              createdAt: widget.service?.createdAt ?? DateTime.now(),
            );
            final navigator = Navigator.of(context);
            await widget.onSave(service);
            if (mounted) {
              navigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class CvEditSheet extends StatefulWidget {
  const CvEditSheet({super.key, required this.profile, required this.onSave});

  final StudentProfile profile;
  final Future<void> Function(String cvUrl) onSave;

  @override
  State<CvEditSheet> createState() => _CvEditSheetState();
}

class _CvEditSheetState extends State<CvEditSheet> {
  late final TextEditingController _cvUrlController;

  @override
  void initState() {
    super.initState();
    _cvUrlController = TextEditingController(text: widget.profile.cvUrl);
  }

  @override
  void dispose() {
    _cvUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: 'Edit CV',
      children: [
        _TextInput(label: 'CV file name or URL', controller: _cvUrlController),
        const Text(
          'Storage upload is a TODO until a Supabase bucket is confirmed.',
          style: TextStyle(color: SkillHubProfileColors.textSub, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _SheetActions(
          primaryLabel: 'Save CV',
          onPrimary: () async {
            final navigator = Navigator.of(context);
            await widget.onSave(_cvUrlController.text.trim());
            if (mounted) {
              navigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class PortfolioItemEditSheet extends StatefulWidget {
  const PortfolioItemEditSheet({
    super.key,
    required this.item,
    required this.profileId,
    required this.onSave,
  });

  final PortfolioItem? item;
  final String profileId;
  final Future<void> Function(PortfolioItem item) onSave;

  @override
  State<PortfolioItemEditSheet> createState() => _PortfolioItemEditSheetState();
}

class _PortfolioItemEditSheetState extends State<PortfolioItemEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _externalUrlController;
  late final TextEditingController _fileUrlController;
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _externalUrlController = TextEditingController(
      text: item?.externalUrl ?? '',
    );
    _fileUrlController = TextEditingController(text: item?.fileUrl ?? '');
    _typeController = TextEditingController(text: item?.itemType ?? 'project');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _externalUrlController.dispose();
    _fileUrlController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: widget.item == null ? 'Add Portfolio Item' : 'Edit Portfolio Item',
      children: [
        _TextInput(label: 'Title', controller: _titleController),
        _TextInput(
          label: 'Description',
          controller: _descriptionController,
          minLines: 3,
        ),
        _TextInput(label: 'External URL', controller: _externalUrlController),
        _TextInput(label: 'File URL', controller: _fileUrlController),
        _TextInput(label: 'Item type', controller: _typeController),
        const Text(
          'File upload is a TODO until profile storage buckets are confirmed.',
          style: TextStyle(color: SkillHubProfileColors.textSub, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _SheetActions(
          primaryLabel: 'Save Item',
          onPrimary: () async {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            final item = PortfolioItem(
              id: widget.item?.id ?? '',
              profileId: widget.item?.profileId ?? widget.profileId,
              title: title,
              description: _descriptionController.text.trim(),
              fileUrl: _fileUrlController.text.trim(),
              externalUrl: _externalUrlController.text.trim(),
              itemType: _typeController.text.trim().isEmpty
                  ? 'project'
                  : _typeController.text.trim(),
              createdAt: widget.item?.createdAt ?? DateTime.now(),
            );
            final navigator = Navigator.of(context);
            await widget.onSave(item);
            if (mounted) {
              navigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: profileSectionTitleStyle()),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.minLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 5,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.primaryLabel, required this.onPrimary});

  final String primaryLabel;
  final Future<void> Function() onPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ),
      ],
    );
  }
}

IconData _visibilityIcon(VisibilityType visibility) {
  return switch (visibility) {
    VisibilityType.private => Icons.lock_outline,
    VisibilityType.connections => Icons.people_outline,
    VisibilityType.lnuPublic => Icons.public,
  };
}
