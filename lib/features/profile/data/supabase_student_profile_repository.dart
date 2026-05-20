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

    final profile = await _loadProfileRow(
      userId: resolvedUserId,
      email: resolvedEmail,
      fallback: fallback.profile,
    );
    final posts = await _loadProfilePosts(
      profile: profile,
      fallback: fallback.posts,
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
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    final modernPayload = {
      ...profile.toSupabaseUpdateMap(),
      if (profile.userId.isNotEmpty) 'user_id': profile.userId,
      if (profile.id.isNotEmpty) 'id': profile.id,
    };
    final legacyPayload = {
      'uid': profile.userId.isNotEmpty ? profile.userId : profile.id,
      'profile_picture_url': profile.avatarUrl,
      'full_name': profile.fullName,
      'college': profile.college,
      'department': profile.department,
      'year_level': profile.yearLevel,
      'username': profile.username.replaceFirst('@', ''),
      'bio': profile.bio,
      'skills': profile.skills,
      'portfolio_gallery': profile.portfolioLinks,
      'availability_status': profile.availability.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (await _tryWrite(() => _client.from('profiles').upsert(modernPayload))) {
      return profile;
    }
    await _tryWrite(() => _client.from('profiles').upsert(legacyPayload));
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
      savedCount: 0,
      isPinned: false,
      createdAt: DateTime.now(),
    );

    if (visibility == VisibilityType.lnuPublic) {
      return _createFeedPost(localPost);
    }

    final row = await _trySelectOne(
      () => _client
          .from('profile_posts')
          .insert({
            'profile_id': profileId,
            'author_id': authorId,
            'content': content,
            'visibility': visibility.value,
            'likes_count': 0,
            'comments_count': 0,
            'saved_count': 0,
            'is_pinned': false,
          })
          .select()
          .limit(1),
    );
    return row == null ? localPost : ProfilePost.fromMap(row);
  }

  @override
  Future<ProfilePost> updatePost(ProfilePost post) async {
    final optionalFeedPayload = {
      'caption': post.content,
      'visibility': post.visibility.value,
      'is_pinned': post.isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final baseFeedPayload = {
      'caption': post.content,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final profilePayload = {
      'content': post.content,
      'visibility': post.visibility.value,
      'attachment_url': post.attachment?.url,
      'attachment_type': post.attachment?.type,
      'saved_count': post.savedCount,
      'is_pinned': post.isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final feedRow =
        await _trySelectOne(
          () => _client
              .from('posts')
              .update(optionalFeedPayload)
              .eq('id', post.id)
              .select()
              .limit(1),
        ) ??
        await _trySelectOne(
          () => _client
              .from('posts')
              .update(baseFeedPayload)
              .eq('id', post.id)
              .select()
              .limit(1),
        );
    if (feedRow != null) {
      return ProfilePost.fromMap(feedRow).copyWith(
        profileId: post.profileId,
        visibility: post.visibility,
        isPinned: post.isPinned,
      );
    }

    final profileRow = await _trySelectOne(
      () => _client
          .from('profile_posts')
          .update(profilePayload)
          .eq('id', post.id)
          .select()
          .limit(1),
    );
    return profileRow == null ? post : ProfilePost.fromMap(profileRow);
  }

  @override
  Future<void> deletePost(ProfilePost post) async {
    final deletedFeed = await _tryWrite(
      () => _client.from('posts').delete().eq('id', post.id),
    );
    if (deletedFeed) {
      return;
    }
    await _tryWrite(
      () => _client.from('profile_posts').delete().eq('id', post.id),
    );
  }

  @override
  Future<ProfilePost> updatePostVisibility({
    required ProfilePost post,
    required VisibilityType visibility,
  }) {
    return updatePost(post.copyWith(visibility: visibility));
  }

  @override
  Future<ProfilePost> pinPost({
    required ProfilePost post,
    required bool pinned,
  }) async {
    final updated = post.copyWith(isPinned: pinned);
    final feedRow = await _trySelectOne(
      () => _client
          .from('posts')
          .update({
            'is_pinned': pinned,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', post.id)
          .select()
          .limit(1),
    );
    if (feedRow != null) {
      return ProfilePost.fromMap(
        feedRow,
      ).copyWith(profileId: post.profileId, isPinned: pinned);
    }
    final profileRow = await _trySelectOne(
      () => _client
          .from('profile_posts')
          .update({
            'is_pinned': pinned,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', post.id)
          .select()
          .limit(1),
    );
    return profileRow == null ? updated : ProfilePost.fromMap(profileRow);
  }

  @override
  Future<void> savePost({
    required String postId,
    required String userId,
  }) async {
    final inserted = await _tryWrite(
      () => _client.from('saved_posts').upsert({
        'post_id': postId,
        'user_id': userId,
      }),
    );
    if (inserted) {
      await _tryWrite(
        () => _client
            .from('posts')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', postId),
      );
    }
  }

  @override
  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    await _tryWrite(
      () => _client
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId),
    );
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reporterId,
  }) async {
    final written = await _tryWrite(
      () => _client.from('post_reports').insert({
        'post_id': postId,
        'reporter_id': reporterId,
        'reason': 'reported_from_profile',
      }),
    );
    if (!written) {
      throw const ProfileActionBlocked('Post reports are unavailable.');
    }
  }

  @override
  Future<ProfileService> createService(ProfileService service) async {
    final payload = _servicePayload(service, includeId: _isUuid(service.id));
    final row = await _trySelectOne(
      () => _client.from('profile_services').insert(payload).select().limit(1),
    );
    return row == null ? service : ProfileService.fromMap(row);
  }

  @override
  Future<ProfileService> updateService(ProfileService service) async {
    final row = await _trySelectOne(
      () => _client
          .from('profile_services')
          .update({
            ..._servicePayload(service, includeId: false),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', service.id)
          .select()
          .limit(1),
    );
    return row == null ? service : ProfileService.fromMap(row);
  }

  @override
  Future<void> deleteService(ProfileService service) async {
    await _tryWrite(
      () => _client.from('profile_services').delete().eq('id', service.id),
    );
  }

  @override
  Future<StudentProfile> updateCv({
    required StudentProfile profile,
    required String cvUrl,
  }) {
    return updateProfile(profile.copyWith(cvUrl: cvUrl));
  }

  @override
  Future<PortfolioItem> createPortfolioItem(PortfolioItem item) async {
    final payload = _portfolioPayload(item, includeId: _isUuid(item.id));
    final row = await _trySelectOne(
      () => _client
          .from('profile_portfolio_items')
          .insert(payload)
          .select()
          .limit(1),
    );
    return row == null ? item : PortfolioItem.fromMap(row);
  }

  @override
  Future<PortfolioItem> updatePortfolioItem(PortfolioItem item) async {
    final row = await _trySelectOne(
      () => _client
          .from('profile_portfolio_items')
          .update({
            ..._portfolioPayload(item, includeId: false),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', item.id)
          .select()
          .limit(1),
    );
    return row == null ? item : PortfolioItem.fromMap(row);
  }

  @override
  Future<void> deletePortfolioItem(PortfolioItem item) async {
    await _tryWrite(
      () => _client.from('profile_portfolio_items').delete().eq('id', item.id),
    );
  }

  @override
  Future<ProfileReview> createReview({
    required ProfileReview review,
    required String profileOwnerId,
    required bool completedCommission,
  }) async {
    if (review.reviewerId == profileOwnerId) {
      throw const ProfileActionBlocked('You cannot review your own profile.');
    }
    if (!completedCommission) {
      throw const ProfileActionBlocked(
        'Reviews require a completed commission.',
      );
    }

    // Normal students should never get update/delete review methods in this
    // repository. Admin/moderator review removal belongs in an admin surface,
    // with RLS policies denying profile-page review edits and deletes.
    final row = await _trySelectOne(
      () => _client
          .from('profile_reviews')
          .insert(review.toMap())
          .select()
          .limit(1),
    );
    return row == null ? review : ProfileReview.fromMap(row);
  }

  @override
  Future<void> requestCommission({
    required ProfileService service,
    required String requesterId,
    required String profileOwnerId,
  }) async {
    if (requesterId == profileOwnerId) {
      throw const ProfileActionBlocked(
        'You cannot request a commission from yourself.',
      );
    }

    // Placeholder until the app has a commission request table/flow. Keeping
    // this in the repository prevents UI code from assuming a backend shape.
  }

  Future<ProfilePost> _createFeedPost(ProfilePost localPost) async {
    final author = await _loadAuthorSnapshot(localPost.authorId);
    final optionalPayload = {
      'author_id': localPost.authorId,
      'author_name': author.name,
      'author_email': author.email,
      'author_department': author.department,
      'type': 'Progress update',
      'caption': localPost.content,
      'media_urls': const <String>[],
      'media_type': 'none',
      'visibility': localPost.visibility.value,
      'is_pinned': false,
      'saved_count': 0,
      'source_profile_id': localPost.profileId,
    };
    final basePayload = {
      'author_id': localPost.authorId,
      'author_name': author.name,
      'author_email': author.email,
      'author_department': author.department,
      'type': 'Progress update',
      'caption': localPost.content,
      'media_urls': const <String>[],
      'media_type': 'none',
    };

    final row =
        await _trySelectOne(
          () => _client.from('posts').insert(optionalPayload).select().limit(1),
        ) ??
        await _trySelectOne(
          () => _client.from('posts').insert(basePayload).select().limit(1),
        );
    return row == null
        ? localPost
        : ProfilePost.fromMap(row).copyWith(
            profileId: localPost.profileId,
            visibility: localPost.visibility,
          );
  }

  Future<StudentProfile> _loadProfileRow({
    required String userId,
    required String? email,
    required StudentProfile fallback,
  }) async {
    Map<String, dynamic>? row;

    for (final key in const ['user_id', 'uid', 'id']) {
      row = await _tryMaybeSingle(
        () => _client.from('profiles').select().eq(key, userId).maybeSingle(),
      );
      if (row != null) {
        break;
      }
    }

    if (row == null) {
      return fallback.copyWith(userId: userId, email: email ?? fallback.email);
    }

    final profile = StudentProfile.fromMap(row);
    return profile.copyWith(
      id: profile.id.isEmpty ? userId : profile.id,
      userId: userId,
      email: email?.isNotEmpty == true ? email : profile.email,
    );
  }

  Future<List<ProfilePost>> _loadProfilePosts({
    required StudentProfile profile,
    required List<ProfilePost> fallback,
  }) async {
    final rows = <Map<String, dynamic>>[];
    final feedRows = await _trySelectMany(
      () => _client
          .from('posts')
          .select()
          .eq('author_id', profile.userId)
          .order('created_at', ascending: false),
    );
    rows.addAll(feedRows);

    final profileRows = await _trySelectMany(
      () => _client
          .from('profile_posts')
          .select()
          .eq('profile_id', profile.id)
          .order('created_at', ascending: false),
    );
    rows.addAll(profileRows);

    if (rows.isEmpty) {
      return fallback;
    }

    final byId = <String, ProfilePost>{};
    for (final row in rows) {
      final post = ProfilePost.fromMap(
        row,
      ).copyWith(profileId: profile.id, authorId: profile.userId);
      byId[post.id] = post;
    }
    final posts = byId.values.toList();
    posts.sort((left, right) {
      if (left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
    return posts;
  }

  Future<List<T>> _loadRows<T>({
    required String table,
    required String profileId,
    required List<T> fallback,
    required T Function(Map<String, dynamic>) mapper,
  }) async {
    final rows = await _trySelectMany(
      () => _client
          .from(table)
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false),
    );
    if (rows.isEmpty) {
      return fallback;
    }
    return rows.map(mapper).toList(growable: false);
  }

  Future<({String name, String email, String department})> _loadAuthorSnapshot(
    String authorId,
  ) async {
    Map<String, dynamic>? row;
    for (final key in const ['uid', 'user_id', 'id']) {
      row = await _tryMaybeSingle(
        () => _client.from('profiles').select().eq(key, authorId).maybeSingle(),
      );
      if (row != null) {
        break;
      }
    }

    final profile = row == null
        ? StudentProfile.empty(userId: authorId)
        : StudentProfile.fromMap(row);
    final email = _client.auth.currentUser?.email ?? profile.email;
    final department = [
      profile.college,
      profile.department,
      if (profile.yearLevel.isNotEmpty) profile.yearLevel,
    ].where((value) => value.isNotEmpty).join(' - ');
    return (
      name: profile.username != '@student'
          ? profile.username
          : profile.fullName,
      email: email,
      department: department.isEmpty ? 'LNU Student' : department,
    );
  }

  Map<String, dynamic> _servicePayload(
    ProfileService service, {
    required bool includeId,
  }) {
    return {
      if (includeId) 'id': service.id,
      'profile_id': service.profileId,
      'title': service.title,
      'description': service.description,
      'category': service.category,
      'price_range': service.priceRange,
      'delivery_time': service.deliveryTime,
      'availability': service.availability.value,
      'created_at': service.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _portfolioPayload(
    PortfolioItem item, {
    required bool includeId,
  }) {
    return {
      if (includeId) 'id': item.id,
      'profile_id': item.profileId,
      'title': item.title,
      'description': item.description,
      'file_url': item.fileUrl,
      'external_url': item.externalUrl,
      'item_type': item.itemType,
      'created_at': item.createdAt.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>?> _tryMaybeSingle(
    Future<Map<String, dynamic>?> Function() action,
  ) async {
    try {
      final row = await action();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _trySelectMany(
    Future<List<dynamic>> Function() action,
  ) async {
    try {
      final rows = await action();
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _trySelectOne(
    Future<List<dynamic>> Function() action,
  ) async {
    final rows = await _trySelectMany(action);
    return rows.isEmpty ? null : rows.first;
  }

  Future<bool> _tryWrite(Future<dynamic> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
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
