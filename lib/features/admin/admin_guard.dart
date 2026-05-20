import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase/supabase.dart';

typedef AdminAccessLoader = Future<AdminAccessDecision> Function();
typedef AdminCurrentUserIdLoader = String? Function();
typedef AdminRoleLookup = Future<List<AdminRoleRecord>> Function(String userId);

enum AdminAccessStatus { allowed, denied, signedOut }

class AdminAccessDecision {
  const AdminAccessDecision._(this.status, {this.message});

  const AdminAccessDecision.allowed() : this._(AdminAccessStatus.allowed);

  const AdminAccessDecision.denied({String? message})
    : this._(AdminAccessStatus.denied, message: message);

  const AdminAccessDecision.signedOut() : this._(AdminAccessStatus.signedOut);

  final AdminAccessStatus status;
  final String? message;
}

class AdminRoleRecord {
  const AdminRoleRecord({required this.table, required this.data});

  final String table;
  final Map<String, dynamic> data;
}

class AdminGuard extends StatefulWidget {
  const AdminGuard({
    super.key,
    required this.child,
    this.loadAccess,
    this.onLoginRequired,
  });

  final Widget child;
  final AdminAccessLoader? loadAccess;
  final VoidCallback? onLoginRequired;

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  late Future<AdminAccessDecision> _accessFuture;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _accessFuture = (widget.loadAccess ?? AdminAccessService().load)();
  }

  @override
  void didUpdateWidget(covariant AdminGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadAccess != widget.loadAccess) {
      _accessFuture = (widget.loadAccess ?? AdminAccessService().load)();
      _redirectScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAccessDecision>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AdminGuardLoading();
        }

        final decision =
            snapshot.data ??
            const AdminAccessDecision.denied(
              message: 'Unable to verify admin access.',
            );

        return switch (decision.status) {
          AdminAccessStatus.allowed => widget.child,
          AdminAccessStatus.denied => AdminAccessDeniedPage(
            message: decision.message,
          ),
          AdminAccessStatus.signedOut => _SignedOutRedirect(
            scheduleRedirect: _scheduleLoginRedirect,
          ),
        };
      },
    );
  }

  void _scheduleLoginRedirect() {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final callback = widget.onLoginRequired;
      if (callback != null) {
        callback();
        return;
      }

      context.go('/login');
    });
  }
}

class AdminAccessService {
  AdminAccessService({
    SupabaseClient? client,
    AdminCurrentUserIdLoader? currentUserIdLoader,
    AdminRoleLookup? roleLookup,
  }) : _client = client,
       _currentUserIdLoader = currentUserIdLoader,
       _roleLookup = roleLookup;

  final SupabaseClient? _client;
  final AdminCurrentUserIdLoader? _currentUserIdLoader;
  final AdminRoleLookup? _roleLookup;

  Future<AdminAccessDecision> load() async {
    final userId = _currentUserIdLoader?.call() ?? _supabaseCurrentUserId();
    if (userId == null) {
      return const AdminAccessDecision.signedOut();
    }

    try {
      final records = await (_roleLookup ?? _loadRoleRecords)(userId);
      if (records.any(_isAdminRecord)) {
        return const AdminAccessDecision.allowed();
      }

      return const AdminAccessDecision.denied();
    } on PostgrestException catch (error) {
      return AdminAccessDecision.denied(
        message: 'Unable to verify admin access: ${error.message}',
      );
    } on StateError catch (error) {
      return AdminAccessDecision.denied(message: error.message);
    }
  }

  String? _supabaseCurrentUserId() {
    return _resolvedClient.auth.currentUser?.id;
  }

  SupabaseClient get _resolvedClient {
    final client = _client;
    if (client != null) {
      return client;
    }

    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Supabase is not configured. Run with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
      );
    }

    return SupabaseClient(supabaseUrl, supabaseAnonKey);
  }

  Future<List<AdminRoleRecord>> _loadRoleRecords(String userId) async {
    final client = _resolvedClient;
    final records = <AdminRoleRecord>[];

    for (final query in _roleQueries) {
      try {
        final data = await client
            .from(query.table)
            .select()
            .eq(query.userIdColumn, userId)
            .maybeSingle();

        if (data != null) {
          records.add(AdminRoleRecord(table: query.table, data: data));
        }
      } on PostgrestException catch (error) {
        if (!_isMissingRoleSource(error)) {
          rethrow;
        }
      }
    }

    return records;
  }

  bool _isAdminRecord(AdminRoleRecord record) {
    final data = record.data;
    final role = _stringValue(data['role']);
    final userType = _stringValue(data['user_type']);
    final accountType = _stringValue(data['account_type']);

    return record.table == 'admin_users' ||
        role == 'admin' ||
        userType == 'admin' ||
        accountType == 'admin' ||
        data['is_admin'] == true ||
        data['isAdmin'] == true;
  }

  bool _isMissingRoleSource(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    return code == '42P01' ||
        code == '42703' ||
        message.contains('does not exist') ||
        message.contains('schema cache');
  }
}

class _RoleQuery {
  const _RoleQuery({required this.table, required this.userIdColumn});

  final String table;
  final String userIdColumn;
}

const _roleQueries = [
  _RoleQuery(table: 'profiles', userIdColumn: 'id'),
  _RoleQuery(table: 'users', userIdColumn: 'id'),
  _RoleQuery(table: 'admin_users', userIdColumn: 'user_id'),
];

class AdminAccessDeniedPage extends StatelessWidget {
  const AdminAccessDeniedPage({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE7E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Color(0xFFA81717),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Access Denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF000011),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message ??
                        'Your account is signed in, but it does not have admin privileges for LNU SkillHub.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to student app'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminGuardLoading extends StatelessWidget {
  const _AdminGuardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FC),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SignedOutRedirect extends StatefulWidget {
  const _SignedOutRedirect({required this.scheduleRedirect});

  final VoidCallback scheduleRedirect;

  @override
  State<_SignedOutRedirect> createState() => _SignedOutRedirectState();
}

class _SignedOutRedirectState extends State<_SignedOutRedirect> {
  @override
  void initState() {
    super.initState();
    widget.scheduleRedirect();
  }

  @override
  Widget build(BuildContext context) {
    return const _AdminGuardLoading();
  }
}

String _stringValue(Object? value) {
  return value is String ? value.toLowerCase().trim() : '';
}

/*
  Supabase admin setup note:

  This guard uses the pure Dart Supabase client. Provide the client through an
  existing app-level setup if one is added later, or run Flutter with:

    --dart-define=SUPABASE_URL=...
    --dart-define=SUPABASE_ANON_KEY=...

  It checks the signed-in Supabase Auth user and then looks for an admin marker
  in these existing/common role sources, without creating migrations:

  - profiles.id == auth.uid with role: "admin" or is_admin: true
  - users.id == auth.uid with role: "admin", is_admin: true, isAdmin: true,
    user_type: "admin", or account_type: "admin"
  - admin_users.user_id == auth.uid, where row existence means admin

  If this project has no existing admin role table/column yet, use a safe
  placeholder convention such as profiles.id = auth.uid and profiles.role =
  "admin". Do not hardcode real passwords in the app.

  This is only frontend route protection. Real admin data must also be protected
  by Supabase Row Level Security policies.
*/
