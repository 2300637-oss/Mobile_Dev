import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../app/app_colors.dart';
import '../../../auth/domain/auth_user.dart';

class CommissionRequestsScreen extends StatelessWidget {
  const CommissionRequestsScreen({super.key, required this.currentUser});

  final AuthUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Commission Requests'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _watchCommissionRequests(currentUser.id),
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

            final pending = requests
                .where((request) => request['status'] == 'pending')
                .length;
            final accepted = requests
                .where(
                  (request) =>
                      request['status'] == 'accepted' ||
                      request['status'] == 'in_progress',
                )
                .length;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _RequestSummary(pending: pending, active: accepted);
                }
                return _CommissionRequestCard(
                  request: requests[index - 1],
                  currentUserId: currentUser.id,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Stream<List<Map<String, dynamic>>> _watchCommissionRequests(
  String userId,
) async* {
  yield await _loadCommissionRequests(userId);
  yield* Stream.periodic(
    const Duration(seconds: 3),
  ).asyncMap((_) => _loadCommissionRequests(userId));
}

Future<List<Map<String, dynamic>>> _loadCommissionRequests(
  String userId,
) async {
  final rows = await Supabase.instance.client
      .from('commission_requests')
      .select()
      .or('client_id.eq.$userId,provider_id.eq.$userId')
      .order('created_at', ascending: false);
  return rows.map((row) => Map<String, dynamic>.from(row)).toList();
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.pending, required this.active});

  final int pending;
  final int active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryNumber(value: pending, label: 'Pending'),
            ),
            Container(width: 1, height: 38, color: const Color(0x33FFFFFF)),
            Expanded(
              child: _SummaryNumber(value: active, label: 'Accepted'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.schoolBusYellow,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 12),
        ),
      ],
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
    final canAccept = isProvider && status == 'pending';
    final canDecline = isProvider && status == 'pending';
    final canMarkDone =
        isProvider && (status == 'accepted' || status == 'in_progress');

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
              style: const TextStyle(color: AppColors.regalNavy),
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
                  onPressed: _isUpdating
                      ? null
                      : () => _updateStatus(
                          status: 'completed',
                          successMessage: 'Commission marked as completed.',
                        ),
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
            if (canAccept || canDecline) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus(
                              status: 'cancelled',
                              successMessage: 'Commission request declined.',
                            ),
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus(
                              status: 'accepted',
                              successMessage: 'Commission request accepted.',
                            ),
                      icon: _isUpdating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.task_alt_outlined),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus({
    required String status,
    required String successMessage,
  }) async {
    setState(() => _isUpdating = true);
    try {
      final payload = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (status == 'completed') {
        payload['completed_at'] = DateTime.now().toIso8601String();
      }
      await Supabase.instance.client
          .from('commission_requests')
          .update(payload)
          .eq('id', widget.request['id']);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
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
    final declined = status == 'cancelled';
    return Chip(
      label: Text(
        completed
            ? 'Completed'
            : declined
            ? 'Declined'
            : _titleCase(status),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: completed
          ? const Color(0xFFFFFFFF)
          : declined
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFFFFFFF),
      labelStyle: TextStyle(
        color: completed
            ? const Color(0xFF00E200)
            : declined
            ? const Color(0xFFFF3838)
            : const Color(0xFF003566),
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
