class UserProfile {
  const UserProfile({
    required this.uid,
    required this.profilePictureUrl,
    required this.fullName,
    required this.studentId,
    required this.college,
    required this.department,
    required this.yearLevel,
    required this.username,
    required this.bio,
    required this.skills,
    required this.portfolioGallery,
    required this.availabilityStatus,
  });

  final String uid;
  final String profilePictureUrl;
  final String fullName;
  final String studentId;
  final String college;
  final String department;
  final String yearLevel;
  final String username;
  final String bio;
  final List<String> skills;
  final List<String> portfolioGallery;
  final String availabilityStatus;

  factory UserProfile.empty(String uid) {
    return UserProfile(
      uid: uid,
      profilePictureUrl: '',
      fullName: '',
      studentId: '',
      college: '',
      department: '',
      yearLevel: '',
      username: '',
      bio: '',
      skills: const [],
      portfolioGallery: const [],
      availabilityStatus: 'available',
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic>? data) {
    final profileData = data ?? const <String, dynamic>{};

    return UserProfile(
      uid: uid,
      profilePictureUrl: profileData['profilePictureUrl'] as String? ?? '',
      fullName: profileData['fullName'] as String? ?? '',
      studentId: profileData['studentId'] as String? ?? '',
      college: profileData['college'] as String? ?? '',
      department:
          profileData['department'] as String? ??
          profileData['collegeDepartment'] as String? ??
          '',
      yearLevel: profileData['yearLevel'] as String? ?? '',
      username: profileData['username'] as String? ?? '',
      bio: profileData['bio'] as String? ?? '',
      skills: List<String>.from(profileData['skills'] as List? ?? const []),
      portfolioGallery: List<String>.from(
        profileData['portfolioGallery'] as List? ?? const [],
      ),
      availabilityStatus:
          profileData['availabilityStatus'] as String? ?? 'available',
    );
  }

  factory UserProfile.fromSupabaseMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String? ?? '',
      profilePictureUrl: data['profile_picture_url'] as String? ?? '',
      fullName: data['full_name'] as String? ?? '',
      studentId: data['student_id'] as String? ?? '',
      college: data['college'] as String? ?? '',
      department: data['department'] as String? ?? '',
      yearLevel: data['year_level'] as String? ?? '',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      skills: List<String>.from(data['skills'] as List? ?? const []),
      portfolioGallery: List<String>.from(
        data['portfolio_gallery'] as List? ?? const [],
      ),
      availabilityStatus: data['availability_status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'profilePictureUrl': profilePictureUrl,
      'fullName': fullName,
      'studentId': studentId,
      'college': college,
      'department': department,
      'yearLevel': yearLevel,
      'username': username,
      'bio': bio,
      'skills': skills,
      'portfolioGallery': portfolioGallery,
      'availabilityStatus': availabilityStatus,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'uid': uid,
      'profile_picture_url': profilePictureUrl,
      'full_name': fullName,
      'student_id': studentId,
      'college': college,
      'department': department,
      'year_level': yearLevel,
      'username': username,
      'bio': bio,
      'skills': skills,
      'portfolio_gallery': portfolioGallery,
      'availability_status': availabilityStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
