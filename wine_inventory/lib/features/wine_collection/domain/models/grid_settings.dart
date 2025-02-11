class GridSettings {
  final int rows;
  final int columns;
  final double cardAspectRatio;

  const GridSettings({
    required this.rows,
    required this.columns,
    this.cardAspectRatio = 0.57,
  });

  factory GridSettings.defaultSettings() {
    return const GridSettings(
      rows: 8,  // Make sure these match your desired grid size
      columns: 3,
      cardAspectRatio: 0.57,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
      'cardAspectRatio': cardAspectRatio,
    };
  }

  factory GridSettings.fromJson(Map<String, dynamic> json) {
    return GridSettings(
      rows: json['rows'] as int? ?? 8,
      columns: json['columns'] as int? ?? 3,
      cardAspectRatio: (json['cardAspectRatio'] as double?) ?? 0.57,
    );
  }

  GridSettings copyWith({
    int? rows,
    int? columns,
    double? cardAspectRatio,
  }) {
    return GridSettings(
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      cardAspectRatio: cardAspectRatio ?? this.cardAspectRatio,
    );
  }
}