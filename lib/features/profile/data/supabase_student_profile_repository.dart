import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_profile_data.dart';
import 'profile_models.dart';
import 'student_profile_repository.dart';

class SupabaseStudentProfileRepository implements StudentProfileRepository {
  const SupabaseStudentProfileRepository({
    required SupabaseClient client,
    StudentProfileRepository? fallbackRepository,
  }) : _client = client,
       _fallbackRepository = fallbackRepository;

  final SupabaseClient _client;
  final StudentProfileRepository? _fallbackRepository;

  StudentProfileRepository get _fallback =>
      _fallbackRepository ?? MockProfileRepository();

  @override
  Future<StudentProfileBundle> loadProfile({
    String? userId,
    String? email,
  }) async {
    final currentUser = _client.auth.currentUser;
    final resolvedUserId = userId ?? currentUser?.id;
    final resolvedEmail = email ?? currentUser?.email;
    final fallback = await _fallback.loadProfile(
      userId: resolvedUserId,
      email: resolvedEmail,
    );

    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return fallback;
    }

    try {
      final profile = await _loadProfileRow(
        userId: resolvedUserId,
        email: resolvedEmail,
        fallback: fallback.profile,
      );
      final posts = await _loadRows<ProfilePost>(
        table: 'profile_posts',
        profileId: profile.id,
        fallback: fallback.posts,
        mapper: ProfilePost.fromMap,
      );
      final services = await _loadRows<ProfileService>(
        table: 'profile_services',
        profileId: profile.id,
        fallback: fallback.services,
        mapper: ProfileService.fromMap,
      );
      final portfolioItems = await _loadRows<PortfolioItem>(
        table: 'profile_portfolio_items',
        profileId: profile.id,
        fallback: fallback.portfolioItems,
        mapper: PortfolioItem.fromMap,
      );
      final reviews = await _loadRows<ProfileReview>(
        table: 'profile_reviews',
        profileId: profile.id,
        fallback: fallback.reviews,
        mapper: ProfileReview.fromMap,
      );

      return StudentProfileBundle(
        profile: profile.copyWith(
          stats: profile.stats.copyWith(
            posts: posts.length,
            reviews: reviews.length,
            rating: _averageRating(reviews, fallback.profile.stats.rating),
          ),
        ),
        posts: posts,
        services: services,
        portfolioItems: portfolioItems,
        reviews: reviews,
        ratingDistribution: _distributionFor(
          reviews,
          fallback.ratingDistribution,
        ),
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    try {
      final payload = profile.toSupabaseUpdateMap();
      if (profile.userId.isNotEmpty) {
        payload['user_id'] = profile.userId;
        payload['uid'] = profile.userId;
      }
      if (profile.id.isNotEmpty) {
        payload['id'] = profile.id;
      }

      await _client.from('profiles').upsert(payload);
    } catch (_) {
      // Missing table/columns or RLS should not break local profile editing.
      // RLS should enforce owner-only profile writes in Supabase.
    }
    return profile;
  }

  @override
  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
  }) async {
    final localPost = ProfilePost(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      authorId: authorId,
      content: content,
      visibility: visibility,
      attachment: null,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    try {
      final rows = await _client
          .from('profile_posts')
          .insert({
            'profile_id': profileId,
            'author_id': authorId,
            'content': content,
            'visibility': visibility.value,
            'likes_count': 0,
            'comments_count': 0,
          })
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        return ProfilePost.fromMap(rows.first);
      }
    } catch (_) {
      // RLS should enforce:
      // - private posts visible only to owner
      // - connections posts visible only to accepted connections
      // - lnu_public posts visible only to verified LNU students
    }

    return localPost;
  }

  Future<StudentProfile> _loadProfileRow({
    required String userId,
    required String? email,
    required StudentProfile fallback,
  }) async {
    Map<String, dynamic>? row;

    try {
      row = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      row = null;
    }

    if (row == null) {
      try {
        row = await _client
            .from('profiles')
            .select()
            .eq('uid', userId)
            .maybeSingle();
      } catch (_) {
        row = null;
      }
    }

    if (row == null) {
      try {
        row = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        row = null;
      }
    }

    if (row == null) {
      return fallback.copyWith(userId: userId, email: email ?? fallback.email);
    }

    return StudentProfile.fromMap(row).copyWith(
      userId: userId,
      email: email?.isNotEmpty == true
          ? email
          : StudentProfile.fromMap(row).email,
    );
  }

  Future<List<T>> _loadRows<T>({
    required String table,
    required String profileId,
    required List<T> fallback,
    required T Function(Map<String, dynamic>) mapper,
  }) async {
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);
      return rows.map((row) => mapper(row)).toList(growable: false);
    } catch (_) {
      return fallback;
    }
  }

  double _averageRating(List<ProfileReview> reviews, double fallbackRating) {
    if (reviews.isEmpty) {
      return fallbackRating;
    }
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return double.parse((total / reviews.length).toStringAsFixed(1));
  }

  List<RatingDistribution> _distributionFor(
    List<ProfileReview> reviews,
    List<RatingDistribution> fallback,
  ) {
    if (reviews.isEmpty) {
      return fallback;
    }

    return List.generate(5, (index) {
      final star = 5 - index;
      final count = reviews.where((review) => review.rating == star).length;
      final percent = ((count / reviews.length) * 100).round();
      return RatingDistribution(star: star, percent: percent);
    });
  }
}
