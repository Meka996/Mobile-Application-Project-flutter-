import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow(
    this.label,
    this.value, {
    super.key,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized ? text.titleMedium : text.bodyMedium,
            ),
          ),
          const SizedBox(width: AppLayout.medium),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasized
                  ? AppTextStyles.price(context)
                  : text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
