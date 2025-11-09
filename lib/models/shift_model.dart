class Shift {
  final int id;
  final String name;
  final String? startTime;
  final String? endTime;
  final String? description;

  Shift({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.description,
  });

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
    id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
    name: j['name']?.toString() ?? '',
    startTime: j['start_time']?.toString(),
    endTime: j['end_time']?.toString(),
    description: j['description']?.toString(),
  );
}
