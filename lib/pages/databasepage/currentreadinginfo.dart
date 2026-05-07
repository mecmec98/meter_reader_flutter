import 'package:flutter/material.dart';

class CurrentReadingInfo extends StatelessWidget {
  final String readingDate;
  final String reader;
  final List<String> zone;
  final List<String> book;

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
          _ChipsRow(
            icon: Icons.location_on_outlined,
            label: 'Zone',
            items: zone,
            showDivider: true,
          ),
          _ChipsRow(
            icon: Icons.menu_book_outlined,
            label: 'Book',
            items: book,
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

class _ChipsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  final bool showDivider;

  const _ChipsRow({
    required this.icon,
    required this.label,
    required this.items,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(height: 4),
                  items.isEmpty
                      ? const Text(
                          '--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: items.map((item) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.blue
                                      .withOpacity(0.3)),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:Color(0xFF1565C0),
                              ),
                            ),
                          )).toList(),
                        ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 14),
      ],
    );
  }
}
