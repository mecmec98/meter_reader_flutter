class FeatureModel {
  final String key;
  final String label;
  final bool enabled;

  FeatureModel({
    required this.key,
    required this.label,
    required this.enabled,
  });

  factory FeatureModel.fromMap(Map<String, dynamic> map) {
    return FeatureModel(
      key: map['key'] as String,
      label: map['label'] as String,
      enabled: (map['enabled'] as int) == 1,
    );
  }
}