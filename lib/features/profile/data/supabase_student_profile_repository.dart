import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_models.dart';
import 'student_profile_repository.dart';

class SupabaseStudentProfileRepository implements StudentProfileRepository {
  const SupabaseStudentProfileRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;
  static final Map<String, StudentProfile> _profileCache = {};
  static final Map<String, List<ProfilePost>> _postCache = {};
  static final Map<String, List<PortfolioItem>> _portfolioCache = {};
  static final Map<String, List<ProfileService>> _serviceCache = {};
  static final Map<String, List<ProfileReview>> _reviewCache = {};

  @override
  Future<StudentProfileBundle> loadProfile({
    String? userId,
    String? email,
  }) async {
    final currentUser = _client.auth.currentUser;
    final resolvedUserId = userId ?? currentUser?.id;
    final resolvedEmail = email ?? currentUser?.email;
    final fallback = _emptyBundle(
      userId: resolvedUserId ?? '',
      email: resolvedEmail ?? '',
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
      final publicPostCount = await _countPublicPosts(profile.userId);
      final combinedProfilePosts = [
        ...(_postCache[profile.id] ?? const <ProfilePost>[]),
        ...posts,
      ];
      final combinedServices = [
        ...(_serviceCache[profile.id] ?? const <ProfileService>[]),
        ...services,
      ];
      final combinedPortfolioItems = [
        ...(_portfolioCache[profile.id] ?? const <PortfolioItem>[]),
        ...portfolioItems,
      ];
      final combinedReviews = [
        ...(_reviewCache[profile.id] ?? const <ProfileReview>[]),
        ...reviews,
      ];

      return StudentProfileBundle(
        profile: (_profileCache[profile.userId] ?? profile).copyWith(
          stats: profile.stats.copyWith(
            posts: publicPostCount + combinedProfilePosts.length,
            reviews: combinedReviews.length,
            rating: _averageRating(
              combinedReviews,
              fallback.profile.stats.rating,
            ),
          ),
        ),
        posts: combinedProfilePosts,
        services: combinedServices,
        portfolioItems: combinedPortfolioItems,
        reviews: combinedReviews,
        ratingDistribution: _distributionFor(
          combinedReviews,
          fallback.ratingDistribution,
        ),
      );
    } catch (_) {
      return fallback;
    }
  }

  StudentProfileBundle _emptyBundle({
    required String userId,
    required String email,
  }) {
    final username = email.contains('@') ? email.split('@').first : '';
    final profile = StudentProfile.empty(userId: userId, email: email).copyWith(
      fullName: email.isEmpty ? 'LNU Student' : email,
      username: username.isEmpty ? '@student' : '@$username',
    );
    return StudentProfileBundle(
      profile: profile,
      posts: const [],
      services: const [],
      portfolioItems: const [],
      reviews: const [],
      ratingDistribution: const [
        RatingDistribution(star: 5, percent: 0),
        RatingDistribution(star: 4, percent: 0),
        RatingDistribution(star: 3, percent: 0),
        RatingDistribution(star: 2, percent: 0),
        RatingDistribution(star: 1, percent: 0),
      ],
    );
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    _profileCache[profile.userId] = profile;
    final uid = profile.userId.isNotEmpty ? profile.userId : profile.id;
    if (uid.isEmpty) {
      return profile;
    }

    final payload = profile.toSupabaseUpdateMap()
      ..remove('id')
      ..remove('user_id')
      ..['uid'] = uid;

    try {
      final rows = await _client
          .from('profiles')
          .upsert(payload, onConflict: 'uid')
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        final saved = StudentProfile.fromMap(
          rows.first,
        ).copyWith(userId: uid, email: profile.email);
        _profileCache[uid] = saved;
        return saved;
      }
    } catch (error) {
      final legacyPayload = Map<String, dynamic>.from(payload)
        ..remove('avatar_url')
        ..remove('cover_url')
        ..remove('cv_url')
        ..remove('portfolio_links')
        ..remove('availability')
        ..remove('profile_visibility');
      final rows = await _client
          .from('profiles')
          .upsert(legacyPayload, onConflict: 'uid')
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        final saved = StudentProfile.fromMap(rows.first).copyWith(
          userId: uid,
          email: profile.email,
          avatarUrl: profile.avatarUrl,
          coverUrl: profile.coverUrl,
          cvUrl: profile.cvUrl,
          portfolioLinks: profile.portfolioLinks,
        );
        _profileCache[uid] = saved;
        return saved;
      }
      throw Exception('Supabase profile save failed: $error');
    }

    throw Exception('Supabase profile save returned no rows.');
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

    _postCache
        .putIfAbsent(profileId, () => <ProfilePost>[])
        .insert(0, localPost);
    return localPost;
  }

  @override
  Future<PortfolioItem> createPortfolioItem({
    required String profileId,
    required String title,
    required String description,
  }) async {
    final localItem = PortfolioItem(
      id: 'local-portfolio-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      title: title,
      description: description,
      fileUrl: '',
      externalUrl: '',
      itemType: 'project',
      createdAt: DateTime.now(),
    );

    try {
      final rows = await _client
          .from('profile_portfolio_items')
          .insert({
            'profile_id': profileId,
            'user_id': _client.auth.currentUser?.id,
            'title': title,
            'description': description,
            'item_type': 'project',
          })
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        return PortfolioItem.fromMap(rows.first);
      }
    } catch (_) {}

    _portfolioCache
        .putIfAbsent(profileId, () => <PortfolioItem>[])
        .insert(0, localItem);
    return localItem;
  }

  @override
  Future<ProfileService> createService({
    required String profileId,
    required String title,
    required String description,
    required String category,
    required String priceRange,
    required String deliveryTime,
    required AvailabilityStatus availability,
  }) async {
    final localService = ProfileService(
      id: 'local-service-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      title: title,
      description: description,
      category: category,
      priceRange: priceRange,
      deliveryTime: deliveryTime,
      availability: availability,
      createdAt: DateTime.now(),
    );

    try {
      final rows = await _client
          .from('profile_services')
          .insert({
            'profile_id': profileId,
            'user_id': _client.auth.currentUser?.id,
            'title': title,
            'description': description,
            'category': category,
            'price_range': priceRange,
            'delivery_time': deliveryTime,
            'availability': availability.value,
          })
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        return ProfileService.fromMap(rows.first);
      }
    } catch (_) {}

    _serviceCache
        .putIfAbsent(profileId, () => <ProfileService>[])
        .insert(0, localService);
    return localService;
  }

  @override
  Future<ProfileReview> createReview({
    required String profileId,
    required String reviewerId,
    required String reviewerName,
    required String serviceTitle,
    required int rating,
    required String comment,
  }) async {
    final safeRating = rating.clamp(1, 5);
    final localReview = ProfileReview(
      id: 'local-review-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerInitials: _initialsForName(reviewerName),
      serviceTitle: serviceTitle,
      rating: safeRating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      final rows = await _client
          .from('profile_reviews')
          .insert({
            'profile_id': profileId,
            'reviewer_id': reviewerId,
            'reviewer_name': reviewerName,
            'reviewer_initials': _initialsForName(reviewerName),
            'service_title': serviceTitle,
            'rating': safeRating,
            'comment': comment,
          })
          .select()
          .limit(1);
      if (rows.isNotEmpty) {
        return ProfileReview.fromMap(rows.first);
      }
    } catch (_) {}

    _reviewCache
        .putIfAbsent(profileId, () => <ProfileReview>[])
        .insert(0, localReview);
    return localReview;
  }

  @override
  Future<void> deletePost({
    required String profileId,
    required String postId,
  }) async {
    _postCache[profileId]?.removeWhere((post) => post.id == postId);
    try {
      await _client.from('profile_posts').delete().eq('id', postId);
    } catch (_) {
      // Keep the local removal even if the profile_posts table/RLS is not ready.
    }
  }

  @override
  Future<String> uploadProfileFile({
    required String userId,
    required String path,
    required String fileName,
    required String bucket,
    String? contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final storagePath =
        '$userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage
        .from(bucket)
        .upload(
          storagePath,
          File(path),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(storagePath);
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

  Future<int> _countPublicPosts(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }
    try {
      final rows = await _client
          .from('posts')
          .select('id')
          .eq('author_id', userId);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  double _averageRating(List<ProfileReview> reviews, double fallbackRating) {
    if (reviews.isEmpty) {
      return fallbackRating;
    }
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return double.parse((total / reviews.length).toStringAsFixed(1));
  }

  String _initialsForName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'LS';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
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
