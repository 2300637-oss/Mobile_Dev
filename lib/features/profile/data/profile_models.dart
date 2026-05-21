enum VisibilityType {
  private,
  connections,
  lnuPublic;

  String get value {
    return switch (this) {
      VisibilityType.private => 'private',
      VisibilityType.connections => 'connections',
      VisibilityType.lnuPublic => 'lnu_public',
    };
  }

  String get label {
    return switch (this) {
      VisibilityType.private => 'Private',
      VisibilityType.connections => 'Connections',
      VisibilityType.lnuPublic => 'LNU Public',
    };
  }

  String get description {
    return switch (this) {
      VisibilityType.private => 'Only me',
      VisibilityType.connections => 'Accepted student connections only',
      VisibilityType.lnuPublic => 'All verified LNU students',
    };
  }

  static VisibilityType fromValue(Object? value) {
    final normalized = value.toString().trim().toLowerCase();
    return switch (normalized) {
      'private' => VisibilityType.private,
      'connections' || 'connection' => VisibilityType.connections,
      'lnu-public' ||
      'lnu_public' ||
      'public' ||
      'lnu public' => VisibilityType.lnuPublic,
      _ => VisibilityType.lnuPublic,
    };
  }
}

enum AvailabilityStatus {
  open,
  closed,
  busy,
  unavailable;

  String get value {
    return switch (this) {
      AvailabilityStatus.open => 'open',
      AvailabilityStatus.closed => 'closed',
      AvailabilityStatus.busy => 'busy',
      AvailabilityStatus.unavailable => 'unavailable',
    };
  }

  String get label {
    return switch (this) {
      AvailabilityStatus.open => 'Open for Commissions',
      AvailabilityStatus.closed => 'Closed',
      AvailabilityStatus.busy => 'Busy',
      AvailabilityStatus.unavailable => 'Unavailable',
    };
  }

  bool get canRequest => this == AvailabilityStatus.open;

  static AvailabilityStatus fromValue(Object? value) {
    final normalized = value.toString().trim().toLowerCase();
    return switch (normalized) {
      'closed' => AvailabilityStatus.closed,
      'busy' => AvailabilityStatus.busy,
      'unavailable' => AvailabilityStatus.unavailable,
      'available' || 'open' || '' => AvailabilityStatus.open,
      _ => AvailabilityStatus.open,
    };
  }
}

class ProfileStats {
  const ProfileStats({
    required this.posts,
    required this.completed,
    required this.reviews,
    required this.rating,
  });

  final int posts;
  final int completed;
  final int reviews;
  final double rating;

  factory ProfileStats.empty() {
    return const ProfileStats(posts: 0, completed: 0, reviews: 0, rating: 0);
  }

  factory ProfileStats.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    return ProfileStats(
      posts: _readInt(source['posts']),
      completed: _readInt(source['completed']),
      reviews: _readInt(source['reviews']),
      rating: _readDouble(source['rating']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'posts': posts,
      'completed': completed,
      'reviews': reviews,
      'rating': rating,
    };
  }

  ProfileStats copyWith({
    int? posts,
    int? completed,
    int? reviews,
    double? rating,
  }) {
    return ProfileStats(
      posts: posts ?? this.posts,
      completed: completed ?? this.completed,
      reviews: reviews ?? this.reviews,
      rating: rating ?? this.rating,
    );
  }
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.username,
    required this.college,
    required this.department,
    required this.yearLevel,
    required this.bio,
    required this.skills,
    required this.availability,
    required this.visibility,
    required this.avatarUrl,
    required this.coverUrl,
    required this.cvUrl,
    required this.verified,
    required this.email,
    required this.contactPreference,
    required this.joinedLabel,
    required this.portfolioLinks,
    required this.stats,
  });

  final String id;
  final String userId;
  final String fullName;
  final String username;
  final String college;
  final String department;
  final String yearLevel;
  final String bio;
  final List<String> skills;
  final AvailabilityStatus availability;
  final VisibilityType visibility;
  final String avatarUrl;
  final String coverUrl;
  final String cvUrl;
  final bool verified;
  final String email;
  final String contactPreference;
  final String joinedLabel;
  final List<String> portfolioLinks;
  final ProfileStats stats;

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'LS';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  factory StudentProfile.empty({String userId = '', String email = ''}) {
    return StudentProfile(
      id: userId,
      userId: userId,
      fullName: 'LNU Student',
      username: '@student',
      college: 'Leyte Normal University',
      department: 'Student',
      yearLevel: 'Student',
      bio: 'Add a short bio to introduce your skills and services.',
      skills: const [],
      availability: AvailabilityStatus.open,
      visibility: VisibilityType.lnuPublic,
      avatarUrl: '',
      coverUrl: '',
      cvUrl: '',
      verified: true,
      email: email,
      contactPreference: 'Message on SkillHub',
      joinedLabel: 'Recently',
      portfolioLinks: const [],
      stats: ProfileStats.empty(),
    );
  }

  factory StudentProfile.fromJson(Map<String, dynamic> data) {
    return StudentProfile.fromMap(data);
  }

  factory StudentProfile.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    final id = _readString(
      source['id'] ??
          source['uid'] ??
          source['profile_id'] ??
          source['user_id'],
    );
    final userId = _readString(source['user_id'] ?? source['uid'] ?? id);
    final rawUsername = _readString(source['username']);
    return StudentProfile(
      id: id,
      userId: userId,
      fullName: _readString(
        source['full_name'] ?? source['name'],
        'LNU Student',
      ),
      username: rawUsername.isEmpty
          ? '@student'
          : rawUsername.startsWith('@')
          ? rawUsername
          : '@$rawUsername',
      college: _readString(source['college'], 'Leyte Normal University'),
      department: _readString(source['department'], 'Student'),
      yearLevel: _readString(
        source['year_level'] ?? source['year'] ?? source['yearLevel'],
        'Student',
      ),
      bio: _readString(
        source['bio'],
        'Add a short bio to introduce your skills and services.',
      ),
      skills: _readStringList(source['skills']),
      availability: AvailabilityStatus.fromValue(
        source['availability'] ?? source['availability_status'],
      ),
      visibility: VisibilityType.fromValue(
        source['profile_visibility'] ?? source['visibility'],
      ),
      avatarUrl: _readString(
        source['avatar_url'] ?? source['profile_picture_url'],
      ),
      coverUrl: _readString(source['cover_url']),
      cvUrl: _readString(source['cv_url']),
      verified:
          _readBool(source['verified'] ?? source['email_verified']) ?? true,
      email: _readString(source['email']),
      contactPreference: _readString(
        source['contact_preference'] ?? source['contactPref'],
        'Message on SkillHub',
      ),
      joinedLabel: _readJoinedLabel(
        source['created_at'] ?? source['joinedDate'],
      ),
      portfolioLinks: _readStringList(
        source['portfolio_links'] ?? source['portfolioLinks'],
      ),
      stats: ProfileStats.fromMap(source['stats'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'username': username.replaceFirst('@', ''),
      'college': college,
      'department': department,
      'year_level': yearLevel,
      'bio': bio,
      'skills': skills,
      'availability': availability.value,
      'profile_visibility': visibility.value,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'cv_url': cvUrl,
      'verified': verified,
      'email': email,
      'contact_preference': contactPreference,
      'portfolio_links': portfolioLinks,
      'stats': stats.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpdateMap() {
    return {
      'full_name': fullName,
      'username': username.replaceFirst('@', ''),
      'college': college,
      'department': department,
      'year_level': yearLevel,
      'bio': bio,
      'skills': skills,
      'availability': availability.value,
      'availability_status': availability.value,
      'profile_visibility': visibility.value,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'cv_url': cvUrl,
      'profile_picture_url': avatarUrl,
      'portfolio_links': portfolioLinks,
      'verified': verified,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  StudentProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? username,
    String? college,
    String? department,
    String? yearLevel,
    String? bio,
    List<String>? skills,
    AvailabilityStatus? availability,
    VisibilityType? visibility,
    String? avatarUrl,
    String? coverUrl,
    String? cvUrl,
    bool? verified,
    String? email,
    String? contactPreference,
    String? joinedLabel,
    List<String>? portfolioLinks,
    ProfileStats? stats,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      college: college ?? this.college,
      department: department ?? this.department,
      yearLevel: yearLevel ?? this.yearLevel,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      visibility: visibility ?? this.visibility,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      verified: verified ?? this.verified,
      email: email ?? this.email,
      contactPreference: contactPreference ?? this.contactPreference,
      joinedLabel: joinedLabel ?? this.joinedLabel,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      stats: stats ?? this.stats,
    );
  }
}

class ProfileAttachment {
  const ProfileAttachment({
    required this.type,
    required this.label,
    required this.url,
  });

  final String type;
  final String label;
  final String url;

  factory ProfileAttachment.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    return ProfileAttachment(
      type: _readString(source['attachment_type'] ?? source['type'], 'preview'),
      label: _readString(source['attachment_label'] ?? source['label']),
      url: _readString(source['attachment_url'] ?? source['url']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attachment_type': type,
      'attachment_label': label,
      'attachment_url': url,
    };
  }
}

class ProfilePost {
  const ProfilePost({
    required this.id,
    required this.profileId,
    required this.authorId,
    required this.content,
    required this.visibility,
    required this.attachment,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String authorId;
  final String content;
  final VisibilityType visibility;
  final ProfileAttachment? attachment;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  factory ProfilePost.fromJson(Map<String, dynamic> data) {
    return ProfilePost.fromMap(data);
  }

  factory ProfilePost.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    final attachmentUrl = _readString(source['attachment_url']);
    final inlineAttachment = source['attachment'] is Map<String, dynamic>
        ? ProfileAttachment.fromMap(
            source['attachment'] as Map<String, dynamic>,
          )
        : null;
    return ProfilePost(
      id: _readString(source['id']),
      profileId: _readString(source['profile_id']),
      authorId: _readString(source['author_id']),
      content: _readString(source['content']),
      visibility: VisibilityType.fromValue(source['visibility']),
      attachment:
          inlineAttachment ??
          (attachmentUrl.isEmpty
              ? null
              : ProfileAttachment(
                  type: _readString(source['attachment_type'], 'file'),
                  label: _readString(source['attachment_label'], 'Attachment'),
                  url: attachmentUrl,
                )),
      likesCount: _readInt(source['likes_count'] ?? source['likes']),
      commentsCount: _readInt(source['comments_count'] ?? source['comments']),
      createdAt: _readDate(source['created_at'] ?? source['date']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'author_id': authorId,
      'content': content,
      'visibility': visibility.value,
      'attachment_url': attachment?.url,
      'attachment_type': attachment?.type,
      'attachment_label': attachment?.label,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfilePost copyWith({
    String? id,
    String? profileId,
    String? authorId,
    String? content,
    VisibilityType? visibility,
    ProfileAttachment? attachment,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
  }) {
    return ProfilePost(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      attachment: attachment ?? this.attachment,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProfileService {
  const ProfileService({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    required this.category,
    required this.priceRange,
    required this.deliveryTime,
    required this.availability,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String title;
  final String description;
  final String category;
  final String priceRange;
  final String deliveryTime;
  final AvailabilityStatus availability;
  final DateTime createdAt;

  factory ProfileService.fromJson(Map<String, dynamic> data) {
    return ProfileService.fromMap(data);
  }

  factory ProfileService.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    return ProfileService(
      id: _readString(source['id']),
      profileId: _readString(source['profile_id']),
      title: _readString(source['title'], 'Untitled service'),
      description: _readString(source['description'] ?? source['desc']),
      category: _readString(source['category'], 'General'),
      priceRange: _readString(source['price_range'] ?? source['price']),
      deliveryTime: _readString(source['delivery_time'] ?? source['delivery']),
      availability: AvailabilityStatus.fromValue(source['availability']),
      createdAt: _readDate(source['created_at']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'title': title,
      'description': description,
      'category': category,
      'price_range': priceRange,
      'delivery_time': deliveryTime,
      'availability': availability.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.externalUrl,
    required this.itemType,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String title;
  final String description;
  final String fileUrl;
  final String externalUrl;
  final String itemType;
  final DateTime createdAt;

  factory PortfolioItem.fromJson(Map<String, dynamic> data) {
    return PortfolioItem.fromMap(data);
  }

  factory PortfolioItem.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    return PortfolioItem(
      id: _readString(source['id']),
      profileId: _readString(source['profile_id']),
      title: _readString(source['title'], 'Untitled work'),
      description: _readString(source['description'] ?? source['desc']),
      fileUrl: _readString(source['file_url']),
      externalUrl: _readString(source['external_url']),
      itemType: _readString(source['item_type'], 'project'),
      createdAt: _readDate(source['created_at']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'external_url': externalUrl,
      'item_type': itemType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProfileReview {
  const ProfileReview({
    required this.id,
    required this.profileId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerInitials,
    required this.serviceTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerInitials;
  final String serviceTitle;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory ProfileReview.fromJson(Map<String, dynamic> data) {
    return ProfileReview.fromMap(data);
  }

  factory ProfileReview.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    final reviewerName = _readString(source['reviewer_name'], 'LNU student');
    return ProfileReview(
      id: _readString(source['id']),
      profileId: _readString(source['profile_id']),
      reviewerId: _readString(source['reviewer_id']),
      reviewerName: reviewerName,
      reviewerInitials: _readString(
        source['reviewer_initials'] ?? source['initials'],
        _initialsFor(reviewerName),
      ),
      serviceTitle: _readString(source['service_title']),
      rating: _readInt(source['rating']).clamp(1, 5).toInt(),
      comment: _readString(source['comment']),
      createdAt: _readDate(source['created_at'] ?? source['date']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_initials': reviewerInitials,
      'service_title': serviceTitle,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RatingDistribution {
  const RatingDistribution({required this.star, required this.percent});

  final int star;
  final int percent;
}

class StudentProfileBundle {
  const StudentProfileBundle({
    required this.profile,
    required this.posts,
    required this.services,
    required this.portfolioItems,
    required this.reviews,
    required this.ratingDistribution,
  });

  final StudentProfile profile;
  final List<ProfilePost> posts;
  final List<ProfileService> services;
  final List<PortfolioItem> portfolioItems;
  final List<ProfileReview> reviews;
  final List<RatingDistribution> ratingDistribution;

  StudentProfileBundle copyWith({
    StudentProfile? profile,
    List<ProfilePost>? posts,
    List<ProfileService>? services,
    List<PortfolioItem>? portfolioItems,
    List<ProfileReview>? reviews,
    List<RatingDistribution>? ratingDistribution,
  }) {
    return StudentProfileBundle(
      profile: profile ?? this.profile,
      posts: posts ?? this.posts,
      services: services ?? this.services,
      portfolioItems: portfolioItems ?? this.portfolioItems,
      reviews: reviews ?? this.reviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
}

String _readString(Object? value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString()) ?? 0;
}

double _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString()) ?? 0;
}

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == '0') {
    return false;
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

DateTime _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

String _readJoinedLabel(Object? value) {
  final text = _readString(value);
  if (text.isEmpty) {
    return 'Recently';
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return text;
  }
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[parsed.month - 1]} ${parsed.year}';
}

String _initialsFor(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return 'LS';
  }
  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
}
