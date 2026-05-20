import 'package:flutter/material.dart';

import 'profile_style.dart';

enum ProfileTab {
  posts,
  services,
  portfolio,
  reviews,
  about;

  String get label {
    return switch (this) {
      ProfileTab.posts => 'Posts',
      ProfileTab.services => 'Services',
      ProfileTab.portfolio => 'CV / Portfolio',
      ProfileTab.reviews => 'Reviews',
      ProfileTab.about => 'About',
    };
  }

  IconData get icon {
    return switch (this) {
      ProfileTab.posts => Icons.forum_outlined,
      ProfileTab.services => Icons.work_outline,
      ProfileTab.portfolio => Icons.layers_outlined,
      ProfileTab.reviews => Icons.star_border,
      ProfileTab.about => Icons.person_outline,
    };
  }
}

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.activeTab,
    required this.onChanged,
  });

  final ProfileTab activeTab;
  final ValueChanged<ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProfileTab.values.map((tab) {
                final selected = tab == activeTab;
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: SizedBox(
                    width: compact ? 136 : constraints.maxWidth / 5 - 6,
                    child: TextButton.icon(
                      key: Key('profile-tab-${tab.name}'),
                      onPressed: () => onChanged(tab),
                      style: TextButton.styleFrom(
                        backgroundColor: selected
                            ? SkillHubProfileColors.navy
                            : Colors.transparent,
                        foregroundColor: selected
                            ? SkillHubProfileColors.white
                            : SkillHubProfileColors.textSub,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(tab.icon, size: 16),
                      label: Text(
                        tab.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
