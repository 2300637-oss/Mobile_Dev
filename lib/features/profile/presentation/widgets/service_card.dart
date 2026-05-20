import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.isOwner,
    required this.onRequest,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfileService service;
  final bool isOwner;
  final VoidCallback onRequest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final open = service.availability.canRequest;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SkillHubProfileColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SkillHubProfileColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(service.category),
              color: SkillHubProfileColors.navy,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.title,
                  style: const TextStyle(
                    color: SkillHubProfileColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isOwner)
                PopupMenuButton<_ServiceAction>(
                  tooltip: 'Service options',
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ServiceAction.edit,
                      child: Text('Edit service'),
                    ),
                    PopupMenuItem(
                      value: _ServiceAction.delete,
                      child: Text('Delete service'),
                    ),
                  ],
                  onSelected: (action) {
                    switch (action) {
                      case _ServiceAction.edit:
                        onEdit();
                      case _ServiceAction.delete:
                        onDelete();
                    }
                  },
                  child: const Icon(Icons.more_horiz, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            service.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SkillHubProfileColors.textSub,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 11),
          _CategoryChip(label: service.category),
          const SizedBox(height: 11),
          _ServiceMeta(
            icon: Icons.sell_outlined,
            label: 'Price',
            value: service.priceRange,
          ),
          _ServiceMeta(
            icon: Icons.schedule_outlined,
            label: 'Delivery',
            value: service.deliveryTime,
          ),
          _ServiceMeta(
            icon: open ? Icons.check_circle_outline : Icons.lock_outline,
            label: 'Availability',
            value: open ? 'Open' : 'Closed',
          ),
          const SizedBox(height: 12),
          if (isOwner)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Owner tools'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: open ? onRequest : null,
                style: FilledButton.styleFrom(
                  backgroundColor: SkillHubProfileColors.navy,
                  foregroundColor: SkillHubProfileColors.white,
                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                  disabledForegroundColor: SkillHubProfileColors.textSub,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  open ? Icons.send_outlined : Icons.lock_outline,
                  size: 15,
                ),
                label: Text(open ? 'Request Commission' : 'Currently Closed'),
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(open ? 'Request Commission' : 'Currently Closed'),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('logo') || normalized.contains('brand')) {
      return Icons.workspace_premium_outlined;
    }
    if (normalized.contains('poster') || normalized.contains('layout')) {
      return Icons.dashboard_customize_outlined;
    }
    if (normalized.contains('ui')) {
      return Icons.layers_outlined;
    }
    return Icons.palette_outlined;
  }
}

enum _ServiceAction { edit, delete }

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 12,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceMeta extends StatelessWidget {
  const _ServiceMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SkillHubProfileColors.textSub),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: SkillHubProfileColors.textSub,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
