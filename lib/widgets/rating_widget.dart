import 'package:flutter/material.dart';
import '../config/theme.dart';

class RatingWidget extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final String label;
  final Color color;
  final double size;

  const RatingWidget({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.color = AppColors.accent,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        ...List.generate(5, (i) {
          final star = i + 1.0;
          final filled = star <= value;
          final half = !filled && star - 0.5 <= value;
          return GestureDetector(
            onTap: onChanged != null ? () => onChanged!(star) : null,
            child: Icon(
              half ? Icons.star_half : filled ? Icons.star : Icons.star_outline,
              color: color,
              size: size,
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          value > 0 ? value.toStringAsFixed(1) : '-',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class RatingBar extends StatelessWidget {
  final double wantToGo;
  final double recommend;
  final int totalRatings;

  const RatingBar({
    super.key,
    required this.wantToGo,
    required this.recommend,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Want to Go', value: wantToGo, color: AppColors.primary),
        const SizedBox(width: 8),
        _Chip(label: 'Recommend', value: recommend, color: AppColors.secondary),
        const Spacer(),
        Text(
          '$totalRatings ratings',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
