import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../controllers/create_post_controller.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _postTypes = [
    'Artwork showcase',
    'Commission open post',
    'Service promotion',
    'Progress update',
    'Announcement',
  ];

  final _captionController = TextEditingController();
  String _selectedType = _postTypes.first;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final postController = context.watch<CreatePostController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (postController.errorMessage != null) ...[
                AuthErrorBanner(
                  message: postController.errorMessage!,
                  onDismissed: postController.clearError,
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Post type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _postTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: postController.isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                enabled: !postController.isSaving,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Caption/description',
                  hintText: 'Share your artwork, service, progress, or update.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _MediaPreview(controller: postController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: postController.isSaving
                          ? null
                          : postController.pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Image'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: postController.isSaving
                          ? null
                          : postController.pickVideo,
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: postController.isSaving
                    ? null
                    : () => _submit(authController, postController),
                icon: postController.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: const Text('Post to feed'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Comments are disabled in LNU Student Skills Commission. Users can only react, view, and share public posts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.regalNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    AuthController authController,
    CreatePostController postController,
  ) async {
    final user = authController.currentUser;
    if (user == null) {
      return;
    }

    final saved = await postController.createPost(
      user: user,
      postType: _selectedType,
      caption: _captionController.text,
    );

    if (saved && mounted) {
      context.go('/home');
    }
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    final file = controller.selectedFile;
    if (file == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF003566)),
        ),
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 40),
                SizedBox(height: 8),
                Text('Attach an image or video'),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.mediaType == 'video') {
      return _SelectedVideo(
        fileName: file.name,
        onClear: controller.clearMedia,
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            tooltip: 'Remove media',
            onPressed: controller.clearMedia,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

class _SelectedVideo extends StatelessWidget {
  const _SelectedVideo({required this.fileName, required this.onClear});

  final String fileName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.schoolBusYellow,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            IconButton(
              tooltip: 'Remove media',
              onPressed: onClear,
              icon: const Icon(Icons.close),
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
