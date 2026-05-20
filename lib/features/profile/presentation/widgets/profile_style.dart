import 'package:flutter/material.dart';

class SkillHubProfileColors {
  const SkillHubProfileColors._();

  static const navy = Color(0xFF000088);
  static const midBlue = Color(0xFF0A1B70);
  static const inkBlack = Color(0xFF000011);
  static const white = Color(0xFFFFFFFF);
  static const yellow = Color(0xFFFFC20A);
  static const gold = Color(0xFFFFD60A);
  static const red = Color(0xFFFF3838);
  static const blueAccent = Color(0xFF2A57DF);
  static const green = Color(0xFF00E200);
  static const grayBg = Color(0xFFF4F6FC);
  static const border = Color(0xFFE2E8F0);
  static const textMain = Color(0xFF1E293B);
  static const textSub = Color(0xFF64748B);
}

BoxDecoration profileCardDecoration({
  Color color = SkillHubProfileColors.white,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: SkillHubProfileColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0F000088), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );
}

TextStyle profileSectionTitleStyle() {
  return const TextStyle(
    color: SkillHubProfileColors.midBlue,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
