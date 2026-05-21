import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class PostComposer extends StatefulWidget {
  const PostComposer({
    super.key,
    required this.profile,
    required this.onPost,
    required this.onToolPressed,
  });

  final StudentProfile profile;
  final void Function(String content, VisibilityType visibility) onPost;
  final ValueChanged<String> onToolPressed;

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  final _controller = TextEditingController();
  VisibilityType _visibility = VisibilityType.lnuPublic;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: SkillHubProfileColors.yellow,
            child: Text(
              widget.profile.initials,
              style: const TextStyle(
                color: SkillHubProfileColors.navy,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('profile-post-input'),
                  controller: _controller,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'What skill update do you want to share?',
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: SkillHubProfileColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: SkillHubProfileColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: SkillHubProfileColors.navy,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 500;
                    final tools = Wrap(
                      spacing: 2,
                      runSpacing: 4,
                      children: [
                        _ToolButton(
                          icon: Icons.image_outlined,
                          label: 'Image',
                          onPressed: () => widget.onToolPressed('Image upload'),
                        ),
                        _ToolButton(
                          icon: Icons.description_outlined,
                          label: 'File/CV',
                          onPressed: () => widget.onToolPressed('File upload'),
                        ),
                        _ToolButton(
                          icon: Icons.layers_outlined,
                          label: 'Portfolio',
                          onPressed: () =>
                              widget.onToolPressed('Portfolio link'),
                        ),
                      ],
                    );
                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _VisibilityButton(
                          visibility: _visibility,
                          onPressed: _chooseVisibility,
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: const Key('profile-post-submit'),
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: SkillHubProfileColors.navy,
                            foregroundColor: SkillHubProfileColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.send_outlined, size: 16),
                          label: const Text('Post'),
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tools,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: tools),
                        actions,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseVisibility() async {
    final selected = await showModalBottomSheet<VisibilityType>(
      context: context,
      showDragHandle: true,
      builder: (context) => _VisibilitySheet(selected: _visibility),
    );

    if (selected != null && mounted) {
      setState(() => _visibility = selected);
    }
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Write something before posting.')),
        );
      return;
    }

    widget.onPost(content, _visibility);
    _controller.clear();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: SkillHubProfileColors.textSub,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.visibility, required this.onPressed});

  final VisibilityType visibility;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('profile-post-visibility'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: SkillHubProfileColors.textMain,
        backgroundColor: const Color(0xFFFFFFFF),
        side: const BorderSide(color: SkillHubProfileColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(_visibilityIcon(visibility), size: 15),
      label: Text(visibility.label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _VisibilitySheet extends StatelessWidget {
  const _VisibilitySheet({required this.selected});

  final VisibilityType selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post Visibility',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final visibility in VisibilityType.values)
              ListTile(
                selected: visibility == selected,
                selectedTileColor: const Color(0xFFFFFFFF),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFFFFF),
                  foregroundColor: SkillHubProfileColors.navy,
                  child: Icon(_visibilityIcon(visibility), size: 18),
                ),
                title: Text(
                  visibility.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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

IconData _visibilityIcon(VisibilityType visibility) {
  return switch (visibility) {
    VisibilityType.private => Icons.lock_outline,
    VisibilityType.connections => Icons.people_outline,
    VisibilityType.lnuPublic => Icons.public,
  };
}
