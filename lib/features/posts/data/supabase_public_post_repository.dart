import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/public_post.dart';
import 'public_post_repository.dart';

class SupabasePublicPostRepository implements PublicPostDataSource {
  SupabasePublicPostRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Stream<List<PublicPost>> watchPosts() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map(PublicPost.fromSupabaseMap).toList(growable: false),
        );
  }

  @override
  Stream<List<PublicPost>> watchPostsByAuthor(String authorId) {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('author_id', authorId)
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map(PublicPost.fromSupabaseMap).toList(growable: false),
        );
  }

  @override
  Stream<List<PublicPost>> watchSharedPostsByUser(String userId) {
    return _client
        .from('post_shares')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((rows) async {
          final postIds = rows
              .map((row) => row['post_id'] as String? ?? '')
              .where((postId) => postId.isNotEmpty)
              .toSet()
              .toList(growable: false);
          if (postIds.isEmpty) {
            return const <PublicPost>[];
          }

          final posts = await _client
              .from('posts')
              .select()
              .inFilter('id', postIds)
              .order('created_at', ascending: false);
          return posts.map(PublicPost.fromSupabaseMap).toList(growable: false);
        });
  }

  @override
  Stream<bool> watchHearted({required String postId, required String userId}) {
    return _client
        .from('post_reactions')
        .stream(primaryKey: ['post_id', 'user_id'])
        .map(
          (rows) => rows.any(
            (row) => row['post_id'] == postId && row['user_id'] == userId,
          ),
        );
  }

  @override
  Stream<List<PostViewer>> watchViewers({required String postId}) {
    return _client
        .from('post_views')
        .stream(primaryKey: ['post_id', 'user_id'])
        .eq('post_id', postId)
        .asyncMap((rows) async {
          final userIds = rows
              .map((row) => row['user_id'] as String? ?? '')
              .where((userId) => userId.isNotEmpty)
              .toList(growable: false);
          if (userIds.isEmpty) {
            return const <PostViewer>[];
          }

          final profiles = await _client
              .from('profiles')
              .select(
                'uid, full_name, username, college, department, year_level',
              )
              .inFilter('uid', userIds);
          final profilesById = {
            for (final profile in profiles) profile['uid'] as String: profile,
          };

          final viewers = rows.map((row) {
            final userId = row['user_id'] as String? ?? '';
            final profile = profilesById[userId] ?? const <String, dynamic>{};
            final fullName = profile['full_name'] as String? ?? '';
            final username = profile['username'] as String? ?? '';
            final college = profile['college'] as String? ?? '';
            final department = profile['department'] as String? ?? '';
            final yearLevel = profile['year_level'] as String? ?? '';
            final viewedAtValue = row['created_at'];

            return PostViewer(
              userId: userId,
              name: fullName.isNotEmpty
                  ? fullName
                  : username.isNotEmpty
                  ? username
                  : 'LNU student',
              detail: [
                college,
                department,
                if (yearLevel.isNotEmpty) 'Year $yearLevel',
              ].where((value) => value.isNotEmpty).join(' - '),
              viewedAt: viewedAtValue is String
                  ? DateTime.tryParse(viewedAtValue)
                  : null,
            );
          }).toList();

          viewers.sort((a, b) {
            final left = a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return viewers;
        });
  }

  @override
  Future<String> createPost(CreatePostDraft draft) async {
    final row = await _client
        .from('posts')
        .insert({
          'author_id': draft.authorId,
          'author_name': draft.authorName,
          'author_email': draft.authorEmail,
          'author_department': draft.authorDepartment,
          'type': draft.type,
          'caption': draft.caption,
          'media_urls': draft.mediaUrls,
          'media_type': draft.mediaType,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<String> uploadPostMedia({
    required String userId,
    required XFile file,
    required String mediaType,
  }) async {
    final nameParts = file.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : mediaType;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final path = '$userId/$timestamp.$extension';
    final contentType = mediaType == 'video' ? 'video/mp4' : 'image/jpeg';

    await _client.storage
        .from('post-media')
        .upload(
          path,
          File(file.path),
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _client.storage.from('post-media').getPublicUrl(path);
  }

  @override
  Future<({String authorName, String authorDepartment})> getAuthorInfo(
    String userId,
  ) async {
    final data = await _client
        .from('profiles')
        .select('full_name, username, college, department, year_level')
        .eq('uid', userId)
        .maybeSingle();
    final profile = data ?? const <String, dynamic>{};
    final fullName = profile['full_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final college = profile['college'] as String? ?? '';
    final department = profile['department'] as String? ?? '';
    final yearLevel = profile['year_level'] as String? ?? '';
    final authorDepartment = [
      college,
      department,
      if (yearLevel.isNotEmpty) 'Year $yearLevel',
    ].where((value) => value.isNotEmpty).join(' - ');

    return (
      authorName: username.isNotEmpty
          ? username
          : fullName.isNotEmpty
          ? fullName
          : 'LNU student',
      authorDepartment: authorDepartment.isEmpty
          ? 'LNU Student'
          : authorDepartment,
    );
  }

  @override
  Future<void> toggleHeart({required String postId, required String userId}) {
    return _client.rpc('toggle_post_heart', params: {'target_post_id': postId});
  }

  @override
  Future<void> markViewed({required String postId, required String userId}) {
    return _client.rpc('mark_post_viewed', params: {'target_post_id': postId});
  }

  @override
  Future<void> markShared({required String postId, required String userId}) {
    return _client.rpc('mark_post_shared', params: {'target_post_id': postId});
  }
}
