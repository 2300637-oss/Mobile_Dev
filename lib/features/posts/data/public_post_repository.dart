import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/public_post.dart';

abstract class PublicPostDataSource {
  Stream<List<PublicPost>> watchPosts();

  Stream<List<PublicPost>> watchPostsByAuthor(String authorId);

  Stream<List<PublicPost>> watchSharedPostsByUser(String userId);

  Stream<bool> watchHearted({required String postId, required String userId});

  Stream<List<PostViewer>> watchViewers({required String postId});

  Future<String> createPost(CreatePostDraft draft);

  Future<String> uploadPostMedia({
    required String userId,
    required XFile file,
    required String mediaType,
  });

  Future<({String authorName, String authorDepartment})> getAuthorInfo(
    String userId,
  );

  Future<void> toggleHeart({required String postId, required String userId});

  Future<void> markViewed({required String postId, required String userId});

  Future<void> markShared({required String postId, required String userId});
}

class PublicPostRepository implements PublicPostDataSource {
  PublicPostRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<PublicPost>> watchPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PublicPost.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<PublicPost>> watchPostsByAuthor(String authorId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map(PublicPost.fromDocument)
              .toList(growable: false);
          posts.sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return posts;
        });
  }

  @override
  Stream<List<PublicPost>> watchSharedPostsByUser(String userId) {
    return _firestore
        .collection('post_shares')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final postIds = snapshot.docs
              .map((doc) => doc.data()['postId'] as String? ?? '')
              .where((postId) => postId.isNotEmpty)
              .toSet()
              .toList(growable: false);
          final posts = <PublicPost>[];

          for (final postId in postIds) {
            final post = await _firestore.collection('posts').doc(postId).get();
            if (post.exists) {
              posts.add(PublicPost.fromDocument(post));
            }
          }

          posts.sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return posts;
        });
  }

  @override
  Stream<bool> watchHearted({required String postId, required String userId}) {
    return _firestore
        .collection('post_reactions')
        .doc(_reactionId(postId: postId, userId: userId))
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  @override
  Stream<List<PostViewer>> watchViewers({required String postId}) {
    return _firestore
        .collection('post_views')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .asyncMap((snapshot) async {
          final viewers = <PostViewer>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String? ?? '';
            if (userId.isEmpty) {
              continue;
            }

            final profile = await _firestore
                .collection('profiles')
                .doc(userId)
                .get();
            final profileData = profile.data() ?? const <String, dynamic>{};
            final fullName = profileData['fullName'] as String? ?? '';
            final username = profileData['username'] as String? ?? '';
            final college = profileData['college'] as String? ?? '';
            final department =
                profileData['department'] as String? ??
                profileData['collegeDepartment'] as String? ??
                '';
            final yearLevel = profileData['yearLevel'] as String? ?? '';
            final createdAt = data['createdAt'];

            viewers.add(
              PostViewer(
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
                viewedAt: createdAt is Timestamp ? createdAt.toDate() : null,
              ),
            );
          }

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
    final doc = _firestore.collection('posts').doc();
    await doc.set({
      'authorId': draft.authorId,
      'authorName': draft.authorName,
      'authorEmail': draft.authorEmail,
      'authorDepartment': draft.authorDepartment,
      'type': draft.type,
      'caption': draft.caption,
      'mediaUrls': draft.mediaUrls,
      'mediaType': draft.mediaType,
      'heartCount': 0,
      'viewCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  @override
  Future<({String authorName, String authorDepartment})> getAuthorInfo(
    String userId,
  ) async {
    final profile = await _firestore.collection('profiles').doc(userId).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final fullName = data['fullName'] as String? ?? '';
    final username = data['username'] as String? ?? '';
    final college = data['college'] as String? ?? '';
    final department =
        data['department'] as String? ??
        data['collegeDepartment'] as String? ??
        '';
    final yearLevel = data['yearLevel'] as String? ?? '';

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
  Future<String> uploadPostMedia({
    required String userId,
    required XFile file,
    required String mediaType,
  }) async {
    final nameParts = file.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : mediaType;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final path = 'posts/$userId/$timestamp.$extension';
    final metadata = SettableMetadata(
      contentType: mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
    );
    final reference = _storage.ref(path);
    await reference.putFile(File(file.path), metadata);
    return reference.getDownloadURL();
  }

  @override
  Future<void> toggleHeart({
    required String postId,
    required String userId,
  }) async {
    final reactionRef = _firestore
        .collection('post_reactions')
        .doc(_reactionId(postId: postId, userId: userId));
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final reaction = await transaction.get(reactionRef);
      if (reaction.exists) {
        transaction.delete(reactionRef);
        transaction.update(postRef, {
          'heartCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.set(reactionRef, {
        'postId': postId,
        'userId': userId,
        'type': 'heart',
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'heartCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> markViewed({required String postId, required String userId}) {
    final viewRef = _firestore
        .collection('post_views')
        .doc(_viewId(postId: postId, userId: userId));
    final postRef = _firestore.collection('posts').doc(postId);

    return _firestore.runTransaction((transaction) async {
      final view = await transaction.get(viewRef);
      if (view.exists) {
        return;
      }

      transaction.set(viewRef, {
        'postId': postId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> markShared({required String postId, required String userId}) {
    final shareRef = _firestore.collection('post_shares').doc();
    final postRef = _firestore.collection('posts').doc(postId);

    return _firestore.runTransaction((transaction) async {
      transaction.set(shareRef, {
        'postId': postId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'shareCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _reactionId({required String postId, required String userId}) {
    return '${postId}_$userId';
  }

  String _viewId({required String postId, required String userId}) {
    return '${postId}_$userId';
  }
}
