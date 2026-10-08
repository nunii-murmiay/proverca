import 'package:flutter/material.dart';
import '../models/brand.dart';

class BrandCard extends StatelessWidget {
  final Brand brand;
  final bool isSelected;
  final ValueChanged<int>? onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const BrandCard({
    super.key,
    required this.brand,
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
      color: brand.isDeleted
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
                  onChanged: (_) => onToggleSelect?.call(brand.id),
                ),
                Expanded(
                  child: Text(
                    brand.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                          brand.isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      brand.country,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (brand.description.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Text(
                  brand.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                if (brand.isDeleted && onRestore != null)
                  IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: onRestore,
                  )
                else if (!brand.isDeleted && onDelete != null)
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
