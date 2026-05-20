import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowStore {
  FollowStore._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  static final Map<String, Set<String>> _followersByUser = {};
  static final Map<String, Set<String>> _followingByUser = {};

  static bool isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _followingByUser[currentUserId]?.contains(targetUserId) ?? false;
  }

  static Future<void> loadForUser(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    try {
      final client = Supabase.instance.client;
      final followerRows = await client
          .from('user_follows')
          .select('follower_id')
          .eq('following_id', userId);
      final followingRows = await client
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', userId);
      _followersByUser[userId] = followerRows
          .map((row) => row['follower_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      _followingByUser[userId] = followingRows
          .map((row) => row['following_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      version.value++;
    } catch (_) {}
  }

  static Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty ||
        targetUserId.isEmpty ||
        currentUserId == targetUserId) {
      return;
    }

    final following = _followingByUser.putIfAbsent(
      currentUserId,
      () => <String>{},
    );
    final followers = _followersByUser.putIfAbsent(
      targetUserId,
      () => <String>{},
    );

    final shouldUnfollow = !following.add(targetUserId);
    if (shouldUnfollow) {
      following.remove(targetUserId);
      followers.remove(currentUserId);
    } else {
      followers.add(currentUserId);
    }
    version.value++;

    try {
      final client = Supabase.instance.client;
      if (shouldUnfollow) {
        await client
            .from('user_follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);
      } else {
        await client.from('user_follows').upsert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });
      }
    } catch (_) {
      // Keep the optimistic in-memory state if the follows table/RLS is not ready.
    }
  }

  static int followers(String userId) {
    return _followersByUser[userId]?.length ?? 0;
  }

  static int following(String userId) {
    return _followingByUser[userId]?.length ?? 0;
  }

  static Set<String> followingIds(String userId) {
    return Set.unmodifiable(_followingByUser[userId] ?? const <String>{});
  }
}
