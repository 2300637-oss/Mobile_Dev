import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search students, posts, services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? const _SearchEmptyState()
                  : FutureBuilder<_SearchResults>(
                      future: _loadResults(_query),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final results =
                            snapshot.data ?? const _SearchResults.empty();
                        if (results.students.isEmpty &&
                            results.posts.isEmpty &&
                            results.services.isEmpty) {
                          return const _NoResults();
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (results.students.isNotEmpty) ...[
                              const _SectionTitle('Students'),
                              for (final student in results.students)
                                _StudentTile(student: student),
                              const SizedBox(height: 14),
                            ],
                            if (results.posts.isNotEmpty) ...[
                              const _SectionTitle('Posts'),
                              for (final post in results.posts)
                                _PostTile(post: post),
                              const SizedBox(height: 14),
                            ],
                            if (results.services.isNotEmpty) ...[
                              const _SectionTitle('Services'),
                              for (final service in results.services)
                                _ServiceTile(service: service),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_SearchResults> _loadResults(String query) async {
    final client = Supabase.instance.client;
    final pattern = '%$query%';

    final students = await client
        .from('profiles')
        .select('uid, full_name, username, college, department, year_level')
        .or(
          'full_name.ilike.$pattern,username.ilike.$pattern,college.ilike.$pattern,department.ilike.$pattern',
        )
        .limit(12);

    final posts = await client
        .from('posts')
        .select('id, author_name, caption, type')
        .or(
          'author_name.ilike.$pattern,caption.ilike.$pattern,type.ilike.$pattern',
        )
        .order('created_at', ascending: false)
        .limit(12);

    final services = await client
        .from('profile_services')
        .select('id, profile_id, title, description, category, price_range')
        .or(
          'title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern',
        )
        .limit(12);

    return _SearchResults(
      students: students.map(_StudentResult.fromMap).toList(growable: false),
      posts: posts.map(_PostResult.fromMap).toList(growable: false),
      services: services.map(_ServiceResult.fromMap).toList(growable: false),
    );
  }
}

class _SearchResults {
  const _SearchResults({
    required this.students,
    required this.posts,
    required this.services,
  });

  const _SearchResults.empty()
    : students = const [],
      posts = const [],
      services = const [];

  final List<_StudentResult> students;
  final List<_PostResult> posts;
  final List<_ServiceResult> services;
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final _StudentResult student;

  @override
  Widget build(BuildContext context) {
    return _SearchTile(
      icon: Icons.person_outline,
      title: student.name,
      subtitle: student.detail,
      onTap: () => context.go('/users/${student.uid}'),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final _PostResult post;

  @override
  Widget build(BuildContext context) {
    return _SearchTile(
      icon: Icons.article_outlined,
      title: post.authorName,
      subtitle: '${post.type} - ${post.caption}',
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Post selected.')));
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final _ServiceResult service;

  @override
  Widget build(BuildContext context) {
    return _SearchTile(
      icon: Icons.design_services_outlined,
      title: service.title,
      subtitle: service.detail,
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Service selected.')));
      },
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.schoolBusYellow,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          subtitle.isEmpty ? 'LNU Student Skills Commission' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search for students, posts, services, or skills.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No results found.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StudentResult {
  const _StudentResult({
    required this.uid,
    required this.name,
    required this.detail,
  });

  final String uid;
  final String name;
  final String detail;

  factory _StudentResult.fromMap(Map<String, dynamic> data) {
    final fullName = data['full_name'] as String? ?? '';
    final username = data['username'] as String? ?? '';
    final college = data['college'] as String? ?? '';
    final department = data['department'] as String? ?? '';
    final yearLevel = data['year_level'] as String? ?? '';
    return _StudentResult(
      uid: data['uid'] as String? ?? '',
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
    );
  }
}

class _PostResult {
  const _PostResult({
    required this.authorName,
    required this.caption,
    required this.type,
  });

  final String authorName;
  final String caption;
  final String type;

  factory _PostResult.fromMap(Map<String, dynamic> data) {
    return _PostResult(
      authorName: data['author_name'] as String? ?? 'LNU student',
      caption: data['caption'] as String? ?? '',
      type: data['type'] as String? ?? 'Post',
    );
  }
}

class _ServiceResult {
  const _ServiceResult({required this.title, required this.detail});

  final String title;
  final String detail;

  factory _ServiceResult.fromMap(Map<String, dynamic> data) {
    final category = data['category'] as String? ?? '';
    final price = data['price_range'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    return _ServiceResult(
      title: data['title'] as String? ?? 'Service',
      detail: [
        category,
        price,
        description,
      ].where((value) => value.isNotEmpty).join(' - '),
    );
  }
}
