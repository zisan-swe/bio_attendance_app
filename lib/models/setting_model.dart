class SettingModel {
  final int? id;
  final String name;
  final String? value;
  final String slug;

  SettingModel({
    this.id,
    required this.name,
    this.value,
    required this.slug,
  });

  /// Convert object to Map (for insert/update in SQLite)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'value': value,
      'slug': slug,
    };

    // Only include id if it’s not null (avoids overriding auto-increment)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Create object from Map (for reading from SQLite)
  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      value: map['value'] as String?,
      slug: map['slug'] as String,
    );
  }

  /// CopyWith for updating values easily
  SettingModel copyWith({
    int? id,
    String? name,
    String? value,
    String? slug,
  }) {
    return SettingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      slug: slug ?? this.slug,
    );
  }
}
