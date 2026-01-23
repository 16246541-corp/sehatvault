class MedicalTestDefinition {
  final String id;
  final String canonicalName;
  final List<String> aliases;
  final String category;
  final List<String> commonUnits;

  MedicalTestDefinition({
    required this.id,
    required this.canonicalName,
    required this.aliases,
    required this.category,
    required this.commonUnits,
  });

  factory MedicalTestDefinition.fromJson(Map<String, dynamic> json) {
    return MedicalTestDefinition(
      id: json['id'] as String,
      canonicalName: json['canonical_name'] as String,
      aliases: List<String>.from(json['aliases'] ?? []),
      category: json['category'] as String,
      commonUnits: List<String>.from(json['common_units'] ?? []),
    );
  }
}
