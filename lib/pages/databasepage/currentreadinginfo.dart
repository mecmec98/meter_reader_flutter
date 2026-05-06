import 'package:flutter/material.dart';
 
class CurrentReadingInfo extends StatelessWidget {
  final String readingDate;
  final String reader;
  final String zone;
  final String book;
 
  const CurrentReadingInfo({
    super.key,
    required this.readingDate,
    required this.reader,
    required this.zone,
    required this.book,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Reading date',
            value: readingDate,
            showDivider: true,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Reader',
            value: reader,
            showDivider: true,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Zone',
            value: zone,
            showDivider: true,
          ),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Book',
            value: book,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
 
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
 
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.showDivider,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
      ],
    );
  }
}