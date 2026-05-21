import 'package:flutter/material.dart';

class SkillHubProfileColors {
  const SkillHubProfileColors._();

  static const navy = Color(0xFF000088);
  static const midBlue = Color(0xFF000088);
  static const inkBlack = Color(0xFF000011);
  static const white = Color(0xFFFFFFFF);
  static const yellow = Color(0xFFFFC300);
  static const gold = Color(0xFFFFD60A);
  static const red = Color(0xFFFF3838);
  static const blueAccent = Color(0xFF003566);
  static const green = Color(0xFF00E200);
  static const grayBg = Color(0xFFFFFFFF);
  static const border = Color(0xFF003566);
  static const textMain = Color(0xFF000011);
  static const textSub = Color(0xFF003566);
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
