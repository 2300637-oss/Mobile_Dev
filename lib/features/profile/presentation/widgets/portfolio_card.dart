import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class PortfolioSection extends StatelessWidget {
  const PortfolioSection({
    super.key,
    required this.profile,
    required this.items,
    required this.onViewCv,
    required this.onDownloadCv,
    required this.onAddLink,
  });

  final StudentProfile profile;
  final List<PortfolioItem> items;
  final VoidCallback onViewCv;
  final VoidCallback onDownloadCv;
  final VoidCallback onAddLink;

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
            cvName: profile.cvUrl.isEmpty ? 'Ana_Reyes_CV.pdf' : profile.cvUrl,
            onView: onViewCv,
            onDownload: onDownloadCv,
          ),
          const SizedBox(height: 16),
          const _SectionHead(title: 'Portfolio Links'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...profile.portfolioLinks.map((link) => _LinkChip(label: link)),
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
                      child: PortfolioCard(item: item),
                    ),
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: const _AddProjectCard(),
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
  const PortfolioCard({super.key, required this.item});

  final PortfolioItem item;

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
                Text(
                  item.title,
                  style: const TextStyle(
                    color: SkillHubProfileColors.textMain,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
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

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.cvName,
    required this.onView,
    required this.onDownload,
  });

  final String cvName;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SkillHubProfileColors.border, width: 1.5),
      ),
      child: Row(
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
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Last updated May 2026 - PDF - 1.2 MB',
                  style: TextStyle(
                    color: SkillHubProfileColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined, size: 15),
            label: const Text('View CV'),
          ),
          IconButton(
            tooltip: 'Download CV',
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
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
    return Chip(
      avatar: const Icon(Icons.open_in_new, size: 14),
      label: Text(label),
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
}

class _AddProjectCard extends StatelessWidget {
  const _AddProjectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
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
    );
  }
}
