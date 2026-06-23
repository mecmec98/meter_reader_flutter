class ServerSettingsModel {
  final String ip;
  final int port;

  ServerSettingsModel({required this.ip, required this.port});

  String get baseUrl => 'http://$ip:$port';

  factory ServerSettingsModel.fromMap(Map<String, dynamic> map) {
    return ServerSettingsModel(
      ip: map['server_ip'] as String,
      port: map['server_port'] as int,
    );
  }
}