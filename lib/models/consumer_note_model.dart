class ConsumerNoteModel {
  final int? id;
  final int masCode;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String readingDate;
  final String readerName;
  final String zb;
  final bool isArchived;
  final DateTime? archivedAt;

  ConsumerNoteModel({
    this.id,
    required this.masCode,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
    required this.readingDate,
    required this.readerName,
    required this.zb,
    this.isArchived = false,
    this.archivedAt,
  });

  factory ConsumerNoteModel.fromMap(Map<String, dynamic> map) {
    return ConsumerNoteModel(
      id: map['_id'] as int?,
      masCode: map['mas_code'] as int,
      noteText: map['note_text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      readingDate: map['reading_date'] as String,
      readerName: map['reader_name'] as String,
      zb: map['zb'] as String,
      isArchived: (map['is_archived'] as int?) == 1,
      archivedAt: map['archived_at'] != null
          ? DateTime.parse(map['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'mas_code': masCode,
      'note_text': noteText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reading_date': readingDate,
      'reader_name': readerName,
      'zb': zb,
      'is_archived': isArchived ? 1 : 0,
      'archived_at': archivedAt?.toIso8601String(),
    };
  }
}
