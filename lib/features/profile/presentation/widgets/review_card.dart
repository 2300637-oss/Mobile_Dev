import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.profile,
    required this.reviews,
    required this.ratingDistribution,
  });

  final StudentProfile profile;
  final List<ProfileReview> reviews;
  final List<RatingDistribution> ratingDistribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RatingBanner(
            profile: profile,
            ratingDistribution: ratingDistribution,
          ),
          const SizedBox(height: 12),
          const _ReviewRuleNotice(),
          const SizedBox(height: 12),
          for (final review in reviews) ...[
            ReviewCard(review: review),
            if (review != reviews.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ProfileReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: SkillHubProfileColors.navy,
                child: Text(
                  review.reviewerInitials,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        color: SkillHubProfileColors.textMain,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'via ${review.serviceTitle}',
                      style: const TextStyle(
                        color: SkillHubProfileColors.textSub,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StarRow(rating: review.rating.toDouble(), size: 13),
                  const SizedBox(height: 3),
                  Text(
                    _formatShortDate(review.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.rating,
    this.size = 15,
    this.color = SkillHubProfileColors.yellow,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rounded;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: size,
            color: filled ? color : const Color(0xFFCBD5E1),
          ),
        );
      }),
    );
  }
}

class _RatingBanner extends StatelessWidget {
  const _RatingBanner({
    required this.profile,
    required this.ratingDistribution,
  });

  final StudentProfile profile;
  final List<RatingDistribution> ratingDistribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            SkillHubProfileColors.inkBlack,
            SkillHubProfileColors.navy,
            SkillHubProfileColors.blueAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final score = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                profile.stats.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: SkillHubProfileColors.yellow,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              StarRow(rating: profile.stats.rating),
              const SizedBox(height: 5),
              Text(
                '${profile.stats.reviews} reviews',
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
              ),
            ],
          );
          final bars = Column(
            children: ratingDistribution.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: Text(
                        '${item.star}',
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.percent / 100,
                          minHeight: 7,
                          backgroundColor: const Color(0x33FFFFFF),
                          valueColor: const AlwaysStoppedAnimation(
                            SkillHubProfileColors.yellow,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${item.percent}%',
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );

          if (compact) {
            return Column(children: [score, const SizedBox(height: 16), bars]);
          }

          return Row(
            children: [
              SizedBox(width: 130, child: score),
              Expanded(child: bars),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewRuleNotice extends StatelessWidget {
  const _ReviewRuleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: SkillHubProfileColors.navy,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only verified students who have completed a commission can leave a review.',
              style: TextStyle(
                color: SkillHubProfileColors.midBlue,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
