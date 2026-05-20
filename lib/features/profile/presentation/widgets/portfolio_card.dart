import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class PortfolioSection extends StatelessWidget {
  const PortfolioSection({
    super.key,
    required this.profile,
    required this.items,
    required this.isOwner,
    required this.onViewCv,
    required this.onDownloadCv,
    required this.onEditCv,
    required this.onAddLink,
    required this.onAddProject,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final StudentProfile profile;
  final List<PortfolioItem> items;
  final bool isOwner;
  final VoidCallback onViewCv;
  final VoidCallback onDownloadCv;
  final VoidCallback onEditCv;
  final VoidCallback onAddLink;
  final VoidCallback onAddProject;
  final ValueChanged<PortfolioItem> onEditItem;
  final ValueChanged<PortfolioItem> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHead(title: 'Curriculum Vitae'),
          const SizedBox(height: 10),
          _CvCard(
            cvName: profile.cvUrl.isEmpty
                ? 'No CV uploaded yet'
                : profile.cvUrl,
            onView: onViewCv,
            onDownload: onDownloadCv,
            onEdit: onEditCv,
            isOwner: isOwner,
          ),
          const SizedBox(height: 16),
          const _SectionHead(title: 'Portfolio Links'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...profile.portfolioLinks.map((link) => _LinkChip(label: link)),
              if (isOwner)
                ActionChip(
                  avatar: const Icon(Icons.add_link, size: 15),
                  label: const Text('Add Link'),
                  onPressed: onAddLink,
                  backgroundColor: const Color(0xFFF0FDF4),
                  labelStyle: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                  ),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionHead(title: 'Featured Work'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 560;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: PortfolioCard(
                        item: item,
                        isOwner: isOwner,
                        onEdit: () => onEditItem(item),
                        onDelete: () => onDeleteItem(item),
                      ),
                    ),
                  if (isOwner)
                    SizedBox(
                      width: twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: _AddProjectCard(onPressed: onAddProject),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({
    super.key,
    required this.item,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  final PortfolioItem item;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SkillHubProfileColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SkillHubProfileColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _gradientFor(item.itemType)),
              child: Center(
                child: Icon(
                  _iconFor(item.itemType),
                  color: SkillHubProfileColors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: SkillHubProfileColors.textMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (isOwner)
                      PopupMenuButton<_PortfolioAction>(
                        tooltip: 'Portfolio options',
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _PortfolioAction.edit,
                            child: Text('Edit item'),
                          ),
                          PopupMenuItem(
                            value: _PortfolioAction.delete,
                            child: Text('Delete item'),
                          ),
                        ],
                        onSelected: (action) {
                          switch (action) {
                            case _PortfolioAction.edit:
                              onEdit?.call();
                            case _PortfolioAction.delete:
                              onDelete?.call();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: SkillHubProfileColors.textSub,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _gradientFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('poster')) {
      return const LinearGradient(
        colors: [SkillHubProfileColors.navy, SkillHubProfileColors.blueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (normalized.contains('illustration')) {
      return const LinearGradient(
        colors: [SkillHubProfileColors.midBlue, SkillHubProfileColors.red],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [SkillHubProfileColors.yellow, SkillHubProfileColors.gold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _iconFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('poster')) {
      return Icons.dashboard_customize_outlined;
    }
    if (normalized.contains('illustration')) {
      return Icons.brush_outlined;
    }
    return Icons.auto_awesome_outlined;
  }
}

enum _PortfolioAction { edit, delete }

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.cvName,
    required this.onView,
    required this.onDownload,
    required this.onEdit,
    required this.isOwner,
  });

  final String cvName;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final hasCv = cvName != 'No CV uploaded yet';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SkillHubProfileColors.border, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final fileInfo = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cvName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCv
                          ? 'Stored in Supabase'
                          : 'Upload a PDF, DOC, or DOCX file',
                      style: const TextStyle(
                        color: SkillHubProfileColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              if (!hasCv)
                TextButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_outlined, size: 15),
                  label: const Text('Upload'),
                )
              else
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('View CV'),
                ),
              IconButton(
                tooltip: 'Download CV',
                onPressed: hasCv ? onDownload : onUpload,
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [fileInfo, const SizedBox(height: 8), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: fileInfo),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: SkillHubProfileColors.yellow,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: profileSectionTitleStyle()),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.open_in_new, size: 14),
      label: Text(label),
      onPressed: () => _openLink(context),
      labelStyle: const TextStyle(
        color: SkillHubProfileColors.blueAccent,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: const Color(0xFFF0F4FF),
      side: const BorderSide(color: Color(0xFFC7D2FE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(
      label.startsWith('http://') || label.startsWith('https://')
          ? label
          : 'https://$label',
    );
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }
}

class _AddProjectCard extends StatelessWidget {
  const _AddProjectCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFBFD),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SkillHubProfileColors.border,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF94A3B8)),
                SizedBox(height: 5),
                Text(
                  'Add Project',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
