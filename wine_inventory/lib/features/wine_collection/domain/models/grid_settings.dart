import 'package:wine_inventory/core/models/currency.dart';

class GridSettings {
  final int rows;
  final int columns;
  final double cardAspectRatio;
  final Currency currency;

  const GridSettings({
    required this.rows,
    required this.columns,
    this.cardAspectRatio = 0.57,
    this.currency = Currency.USD,
  });

  factory GridSettings.defaultSettings() {
    return const GridSettings(
      rows: 3,  
      columns: 3,
      cardAspectRatio: 0.57,
      currency: Currency.USD,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
      'cardAspectRatio': cardAspectRatio,
      'currency': currency.index,
    };
  }

  factory GridSettings.fromJson(Map<String, dynamic> json) {
    return GridSettings(
      rows: json['rows'] as int? ?? 8,
      columns: json['columns'] as int? ?? 3,
      cardAspectRatio: (json['cardAspectRatio'] as double?) ?? 0.57,
      currency: json['currency'] != null 
          ? Currency.values[json['currency'] as int]
          : Currency.USD,
    );
  }

  GridSettings copyWith({
    int? rows,
    int? columns,
    double? cardAspectRatio,
    Currency? currency,
  }) {
    return GridSettings(
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      cardAspectRatio: cardAspectRatio ?? this.cardAspectRatio,
      currency: currency ?? this.currency,
    );
  }
}