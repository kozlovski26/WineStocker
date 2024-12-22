class GridSettings {
  final int rows;
  final int columns;

  const GridSettings({
    required this.rows,
    required this.columns,
  });

  factory GridSettings.defaultSettings() {
    return const GridSettings(
      rows: 8,  // Make sure these match your desired grid size
      columns: 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
    };
  }

  factory GridSettings.fromJson(Map<String, dynamic> json) {
    return GridSettings(
      rows: json['rows'] as int? ?? 8,
      columns: json['columns'] as int? ?? 3,
    );
  }
}