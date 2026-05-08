class DatabaseLogModel {
  final int id;
  final String type;
  final String method;
  final DateTime datetime;

  DatabaseLogModel({
    required this.id,
    required this.type,
    required this.method,
    required this.datetime,
  });

  factory DatabaseLogModel.fromMap(Map<String, dynamic> map) {
    return DatabaseLogModel(
      id: map['id'] as int,
      type: map['type'] as String,
      method: map['method'] as String,
      datetime: DateTime.parse(map['datetime'] as String),
    );
  }
}
