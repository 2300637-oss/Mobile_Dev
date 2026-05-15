class UserProfile {
  const UserProfile({
    required this.uid,
    required this.profilePictureUrl,
    required this.fullName,
    required this.studentId,
    required this.collegeDepartment,
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
  final String collegeDepartment;
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
      collegeDepartment: '',
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
      collegeDepartment: profileData['collegeDepartment'] as String? ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'profilePictureUrl': profilePictureUrl,
      'fullName': fullName,
      'studentId': studentId,
      'collegeDepartment': collegeDepartment,
      'username': username,
      'bio': bio,
      'skills': skills,
      'portfolioGallery': portfolioGallery,
      'availabilityStatus': availabilityStatus,
    };
  }
}
