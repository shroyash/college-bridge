class InstitutionModel {
  final int institutionId;
  final String name;
  final String code;

  const InstitutionModel({
    required this.institutionId,
    required this.name,
    required this.code,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['institutionId'] ?? json['id'];
    final instId = rawId is num
        ? rawId.toInt()
        : (int.tryParse(rawId?.toString() ?? '') ?? 0);

    return InstitutionModel(
      institutionId: instId,
      name: (json['name'] ?? json['institutionName'])?.toString() ?? '',
      code: (json['code'] ?? json['institutionCode'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'institutionId': institutionId,
        'name': name,
        'code': code,
      };
}
