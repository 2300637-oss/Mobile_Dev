import 'profile_models.dart';
import 'student_profile_repository.dart';

class MockProfileRepository implements StudentProfileRepository {
  MockProfileRepository({StudentProfileBundle? initialData})
    : _bundle = initialData ?? mockStudentProfileBundle;

  StudentProfileBundle _bundle;
  int _postCounter = 100;

  @override
  Future<StudentProfileBundle> loadProfile({
    String? userId,
    String? email,
  }) async {
    if ((userId == null || userId.isEmpty) &&
        (email == null || email.isEmpty)) {
      return _bundle;
    }

    return _bundle.copyWith(
      profile: _bundle.profile.copyWith(
        userId: userId?.isNotEmpty == true ? userId : _bundle.profile.userId,
        email: email?.isNotEmpty == true ? email : _bundle.profile.email,
      ),
    );
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    _bundle = _bundle.copyWith(profile: profile);
    return profile;
  }

  @override
  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
    ProfileAttachment? attachment,
  }) async {
    final post = ProfilePost(
      id: 'local-post-${_postCounter++}',
      profileId: profileId,
      authorId: authorId,
      content: content,
      visibility: visibility,
      attachment: attachment,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );
    _bundle = _bundle.copyWith(posts: [post, ..._bundle.posts]);
    return post;
  }

  @override
  Future<PortfolioItem> createPortfolioItem({
    required String profileId,
    required String title,
    required String description,
  }) async {
    final item = PortfolioItem(
      id: 'local-portfolio-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      title: title,
      description: description,
      fileUrl: '',
      externalUrl: '',
      itemType: 'project',
      createdAt: DateTime.now(),
    );
    _bundle = _bundle.copyWith(
      portfolioItems: [item, ..._bundle.portfolioItems],
    );
    return item;
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
    final service = ProfileService(
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
    _bundle = _bundle.copyWith(services: [service, ..._bundle.services]);
    return service;
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
    final review = ProfileReview(
      id: 'local-review-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerInitials: _initialsForName(reviewerName),
      serviceTitle: serviceTitle,
      rating: rating.clamp(1, 5),
      comment: comment,
      createdAt: DateTime.now(),
    );
    _bundle = _bundle.copyWith(reviews: [review, ..._bundle.reviews]);
    return review;
  }

  @override
  Future<void> deletePost({
    required String profileId,
    required String postId,
  }) async {
    _bundle = _bundle.copyWith(
      posts: _bundle.posts.where((post) => post.id != postId).toList(),
      profile: _bundle.profile.copyWith(
        stats: _bundle.profile.stats.copyWith(
          posts: (_bundle.profile.stats.posts - 1).clamp(0, 1 << 31),
        ),
      ),
    );
  }

  @override
  Future<String> uploadProfileFile({
    required String userId,
    required String path,
    required String fileName,
    required String bucket,
    String? contentType,
  }) async {
    return path;
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
}

final mockStudentProfileBundle = StudentProfileBundle(
  profile: mockStudentProfile,
  posts: mockProfilePosts,
  services: mockProfileServices,
  portfolioItems: mockPortfolioItems,
  reviews: mockProfileReviews,
  ratingDistribution: mockRatingDistribution,
);

final mockStudentProfile = StudentProfile(
  id: 'profile-ana-reyes',
  userId: '00000000-0000-4000-8000-000000000001',
  fullName: 'Ana Reyes',
  username: '@ana.draws',
  college: 'CAS',
  department: 'Fine Arts',
  yearLevel: '3rd Year',
  bio:
      'Digital artist and student creative offering portrait, logo, and layout commissions for LNU students. Passionate about brand identity, illustration, and visual storytelling.',
  skills: const [
    'Digital Art',
    'Logo Design',
    'Poster Layout',
    'Branding',
    'Illustration',
  ],
  availability: AvailabilityStatus.open,
  visibility: VisibilityType.lnuPublic,
  avatarUrl: '',
  coverUrl: '',
  cvUrl: '',
  verified: true,
  email: 'ana.reyes@lnu.edu.ph',
  contactPreference: 'Message on SkillHub',
  joinedLabel: 'August 2023',
  portfolioLinks: const ['behance.net/ana-draws'],
  stats: const ProfileStats(posts: 12, completed: 47, reviews: 23, rating: 4.8),
);

final mockProfilePosts = [
  ProfilePost(
    id: 'post-1',
    profileId: 'profile-ana-reyes',
    authorId: '00000000-0000-4000-8000-000000000001',
    content:
        "Commission slots open! I'm now accepting digital portrait commissions for the second semester. Full-color bust portraits start at PHP 250. Semi-realistic and chibi styles available. Slots are limited. Drop me a message to reserve yours. #LNUSkillHub #DigitalArt #Commission",
    visibility: VisibilityType.lnuPublic,
    attachment: const ProfileAttachment(
      type: 'preview',
      label: 'Commission Rate Sheet - May 2026',
      url: '',
    ),
    likesCount: 34,
    commentsCount: 12,
    createdAt: DateTime(2026, 5, 18),
  ),
  ProfilePost(
    id: 'post-2',
    profileId: 'profile-ana-reyes',
    authorId: '00000000-0000-4000-8000-000000000001',
    content:
        "Just wrapped up a brand identity pack for a student org here at LNU. Included a logo, color palette, letterhead, and three social media templates. Portfolio update is live in the CV / Portfolio tab.",
    visibility: VisibilityType.connections,
    attachment: const ProfileAttachment(
      type: 'preview',
      label: 'Brand Identity Pack - Student Org',
      url: '',
    ),
    likesCount: 58,
    commentsCount: 17,
    createdAt: DateTime(2026, 5, 10),
  ),
  ProfilePost(
    id: 'post-3',
    profileId: 'profile-ana-reyes',
    authorId: '00000000-0000-4000-8000-000000000001',
    content:
        'Here is a school org poster layout I designed for a cultural event last April. Minimalist meets retro Filipiniana vibes. Open to layout commissions for tarpaulins, event posters, and academic infographics.',
    visibility: VisibilityType.lnuPublic,
    attachment: const ProfileAttachment(
      type: 'preview',
      label: 'Cultural Org Poster - April 2026',
      url: '',
    ),
    likesCount: 91,
    commentsCount: 22,
    createdAt: DateTime(2026, 4, 28),
  ),
];

final mockProfileServices = [
  ProfileService(
    id: 'service-1',
    profileId: 'profile-ana-reyes',
    title: 'Digital Portrait Illustration',
    description:
        'Bust to full-body digital portraits in semi-realistic or chibi style. Includes one revision round.',
    category: 'Digital Art',
    priceRange: 'PHP 250 - PHP 600',
    deliveryTime: '5-7 days',
    availability: AvailabilityStatus.open,
    createdAt: DateTime(2026, 5, 1),
  ),
  ProfileService(
    id: 'service-2',
    profileId: 'profile-ana-reyes',
    title: 'Logo Design for Student Orgs',
    description:
        'Original logo with 2 concepts, 3 revision rounds, and delivery in AI and PNG formats.',
    category: 'Branding',
    priceRange: 'PHP 300 - PHP 800',
    deliveryTime: '7-10 days',
    availability: AvailabilityStatus.open,
    createdAt: DateTime(2026, 5, 1),
  ),
  ProfileService(
    id: 'service-3',
    profileId: 'profile-ana-reyes',
    title: 'Academic Poster Layout',
    description:
        'Clean, print-ready poster layouts for research, events, or org announcements. Tarpaulin-ready.',
    category: 'Poster Layout',
    priceRange: 'PHP 150 - PHP 350',
    deliveryTime: '3-5 days',
    availability: AvailabilityStatus.open,
    createdAt: DateTime(2026, 5, 1),
  ),
  ProfileService(
    id: 'service-4',
    profileId: 'profile-ana-reyes',
    title: 'Basic UI/UX Mockup',
    description:
        'Wireframe-to-mockup design for school projects, capstone presentations, or personal apps.',
    category: 'UI/UX Design',
    priceRange: 'PHP 500 - PHP 1,200',
    deliveryTime: '10-14 days',
    availability: AvailabilityStatus.closed,
    createdAt: DateTime(2026, 5, 1),
  ),
];

final mockPortfolioItems = [
  PortfolioItem(
    id: 'portfolio-1',
    profileId: 'profile-ana-reyes',
    title: 'Brand Identity Pack',
    description: 'Student org branding',
    fileUrl: '',
    externalUrl: '',
    itemType: 'branding',
    createdAt: DateTime(2026, 5, 1),
  ),
  PortfolioItem(
    id: 'portfolio-2',
    profileId: 'profile-ana-reyes',
    title: 'Student Org Poster Set',
    description: '6-piece event poster series',
    fileUrl: '',
    externalUrl: '',
    itemType: 'poster',
    createdAt: DateTime(2026, 4, 20),
  ),
  PortfolioItem(
    id: 'portfolio-3',
    profileId: 'profile-ana-reyes',
    title: 'Portrait Commission Collection',
    description: '12 client portraits',
    fileUrl: '',
    externalUrl: '',
    itemType: 'illustration',
    createdAt: DateTime(2026, 4, 2),
  ),
];

final mockProfileReviews = [
  ProfileReview(
    id: 'review-1',
    profileId: 'profile-ana-reyes',
    reviewerId: 'reviewer-1',
    reviewerName: 'Mark Villanueva',
    reviewerInitials: 'MV',
    serviceTitle: 'Digital Portrait Illustration',
    rating: 5,
    comment:
        'Ana delivered my portrait way ahead of schedule. The resemblance and detail are amazing. The semi-realistic style is exactly what I wanted for my LinkedIn profile.',
    createdAt: DateTime(2026, 5, 12),
  ),
  ProfileReview(
    id: 'review-2',
    profileId: 'profile-ana-reyes',
    reviewerId: 'reviewer-2',
    reviewerName: 'Carla Mendoza',
    reviewerInitials: 'CM',
    serviceTitle: 'Logo Design for Student Orgs',
    rating: 5,
    comment:
        "Our org logo turned out perfect. She was very patient with revisions and gave us options we didn't even think to ask for.",
    createdAt: DateTime(2026, 4, 20),
  ),
  ProfileReview(
    id: 'review-3',
    profileId: 'profile-ana-reyes',
    reviewerId: 'reviewer-3',
    reviewerName: 'Joel Ramos',
    reviewerInitials: 'JR',
    serviceTitle: 'Academic Poster Layout',
    rating: 4,
    comment:
        'Very professional and easy to communicate with. The poster layout was clean and my thesis panel loved it.',
    createdAt: DateTime(2026, 3, 5),
  ),
];

const mockRatingDistribution = [
  RatingDistribution(star: 5, percent: 72),
  RatingDistribution(star: 4, percent: 18),
  RatingDistribution(star: 3, percent: 7),
  RatingDistribution(star: 2, percent: 2),
  RatingDistribution(star: 1, percent: 1),
];
