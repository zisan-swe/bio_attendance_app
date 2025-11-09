class Department {
  final int id;
  final String name;
  final String? code;
  final String? description;

  Department({required this.id, required this.name, this.code, this.description});

  factory Department.fromJson(Map<String, dynamic> j) => Department(
    id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
    name: j['name']?.toString() ?? '',
    code: j['code']?.toString(),
    description: j['description']?.toString(),
  );
}
