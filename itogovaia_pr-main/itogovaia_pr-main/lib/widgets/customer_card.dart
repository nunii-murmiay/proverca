import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final ValueChanged<int>? onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const CustomerCard({
    super.key,
    required this.customer,
    this.isSelected = false,
    this.onToggleSelect,
    this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
      ),
      color: customer.isDeleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.15)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect?.call(customer.id),
                ),
                Expanded(
                  child: Text(
                    customer.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: customer.isDeleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Chip(
                  label: Text(customer.card.level),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.email),
                  Text(customer.phone),
                  Text(
                    'Карта ${customer.card.number} · ${customer.card.points} баллов',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                if (customer.isDeleted && onRestore != null)
                  IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: onRestore,
                  )
                else if (!customer.isDeleted && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
