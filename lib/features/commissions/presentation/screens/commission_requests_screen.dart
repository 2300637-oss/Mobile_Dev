import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../app/app_colors.dart';
import '../../../auth/domain/auth_user.dart';

class CommissionRequestsScreen extends StatelessWidget {
  const CommissionRequestsScreen({super.key, required this.currentUser});

  final AuthUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commission Requests')),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('commission_requests')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false)
              .map(
                (rows) => rows
                    .where(
                      (row) =>
                          row['client_id'] == currentUser.id ||
                          row['provider_id'] == currentUser.id,
                    )
                    .toList(growable: false),
              ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _SetupMessage();
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data ?? const <Map<String, dynamic>>[];
            if (requests.isEmpty) {
              return const _EmptyRequests();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _CommissionRequestCard(
                request: requests[index],
                currentUserId: currentUser.id,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommissionRequestCard extends StatefulWidget {
  const _CommissionRequestCard({
    required this.request,
    required this.currentUserId,
  });

  final Map<String, dynamic> request;
  final String currentUserId;

  @override
  State<_CommissionRequestCard> createState() => _CommissionRequestCardState();
}

class _CommissionRequestCardState extends State<_CommissionRequestCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final status = (request['status'] ?? 'pending').toString();
    final isProvider = request['provider_id'] == widget.currentUserId;
    final canMarkDone =
        isProvider && status != 'completed' && status != 'cancelled';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (request['service_title'] ?? 'Commission request')
                        .toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isProvider
                  ? 'Client: ${(request['client_name'] ?? 'LNU student')}'
                  : 'Artist: ${(request['provider_name'] ?? 'LNU student')}',
              style: const TextStyle(color: Colors.black54),
            ),
            if ((request['note'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text((request['note'] ?? '').toString()),
            ],
            if (canMarkDone) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isUpdating ? null : _markCompleted,
                  icon: _isUpdating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Commission Done'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markCompleted() async {
    setState(() => _isUpdating = true);
    try {
      await Supabase.instance.client
          .from('commission_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.request['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission marked as completed.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update commission status.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final completed = status == 'completed';
    return Chip(
      label: Text(completed ? 'Completed' : _titleCase(status)),
      visualDensity: VisualDensity.compact,
      backgroundColor: completed
          ? const Color(0xFFE7F8EF)
          : const Color(0xFFFFF7E0),
      labelStyle: TextStyle(
        color: completed ? const Color(0xFF12703A) : const Color(0xFF8A5A00),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide.none,
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No commission requests yet. Open another student profile, tap an offer, then request a commission.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SetupMessage extends StatelessWidget {
  const _SetupMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Commission requests are not set up in Supabase yet. Run the latest Supabase profile setup SQL, then reopen this page.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
