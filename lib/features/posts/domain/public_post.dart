import 'package:cloud_firestore/cloud_firestore.dart';

class PublicPost {
  const PublicPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.authorDepartment,
    required this.type,
    required this.caption,
    required this.mediaUrls,
    required this.mediaType,
    required this.heartCount,
    required this.viewCount,
    required this.shareCount,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String authorDepartment;
  final String type;
  final String caption;
  final List<String> mediaUrls;
  final String mediaType;
  final int heartCount;
  final int viewCount;
  final int shareCount;
  final DateTime? createdAt;

  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasVideo => mediaType == 'video';

  factory PublicPost.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAtValue = data['createdAt'];

    return PublicPost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'LNU student',
      authorEmail: data['authorEmail'] as String? ?? '',
      authorDepartment: data['authorDepartment'] as String? ?? '',
      type: data['type'] as String? ?? 'Artwork showcase',
      caption: data['caption'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? const []),
      mediaType: data['mediaType'] as String? ?? 'none',
      heartCount: data['heartCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
    );
  }

  factory PublicPost.fromSupabaseMap(Map<String, dynamic> data) {
    final createdAtValue = data['created_at'];

    return PublicPost(
      id: data['id'] as String? ?? '',
      authorId: data['author_id'] as String? ?? '',
      authorName: data['author_name'] as String? ?? 'LNU student',
      authorEmail: data['author_email'] as String? ?? '',
      authorDepartment: data['author_department'] as String? ?? '',
      type: data['type'] as String? ?? 'Artwork showcase',
      caption: data['caption'] as String? ?? '',
      mediaUrls: List<String>.from(data['media_urls'] as List? ?? const []),
      mediaType: data['media_type'] as String? ?? 'none',
      heartCount: data['heart_count'] as int? ?? 0,
      viewCount: data['view_count'] as int? ?? 0,
      shareCount: data['share_count'] as int? ?? 0,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
    );
  }
}

class CreatePostDraft {
  const CreatePostDraft({
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.authorDepartment,
    required this.type,
    required this.caption,
    required this.mediaUrls,
    required this.mediaType,
  });

  final String authorId;
  final String authorName;
  final String authorEmail;
  final String authorDepartment;
  final String type;
  final String caption;
  final List<String> mediaUrls;
  final String mediaType;
}

class PostViewer {
  const PostViewer({
    required this.userId,
    required this.name,
    required this.detail,
    required this.viewedAt,
  });

  final String userId;
  final String name;
  final String detail;
  final DateTime? viewedAt;
}
