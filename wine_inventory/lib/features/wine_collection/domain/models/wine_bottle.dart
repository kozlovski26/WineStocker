import 'package:wine_inventory/core/models/wine_type.dart';

// Enum for wine source
enum WineSource {
  fridge,  // Wine stored in the wine fridge
  drinkList  // Wine in drink list/consumed
}

class WineBottle {
  String? name;
  String? winery;
  String? year;
  String? notes;
  String? country;
  DateTime? dateAdded;
  DateTime? dateDrunk;
  String? imagePath;
  WineType? type;
  double? rating;
  // TODO: Fix price handling issues before re-enabling
  double? price; // Keep the field but handle differently
  bool isFavorite;
  bool isDrunk;
  String? ownerId; // Added owner ID for trading feature
  bool isForTrade; // Added trade status
  Map<String, dynamic>? metadata; // Added metadata for storing additional information
  WineSource source; // Added source to track if wine is from fridge or external

  WineBottle({
    this.name,
    this.winery,
    this.year,
    this.notes,
    this.country,
    this.dateAdded,
    this.dateDrunk,
    this.imagePath,
    this.type,
    this.rating,
    this.price, // Keep this parameter
    this.isFavorite = false,
    this.isDrunk = false,
    this.ownerId,
    this.isForTrade = false,
    this.metadata,
    this.source = WineSource.fridge, // Default to fridge
  });

  // Get currency code from metadata
  String? get currency => metadata != null ? metadata!['currency'] as String? : null;

  bool get isEmpty => name == null && imagePath == null;

  WineBottle copyWith({
    String? name,
    String? winery,
    String? year,
    String? notes,
    String? country,
    DateTime? dateAdded,
    DateTime? dateDrunk,
    String? imagePath,
    WineType? type,
    double? rating,
    double? price,
    bool? isFavorite,
    bool? isDrunk,
    String? ownerId,
    bool? isForTrade,
    Map<String, dynamic>? metadata,
    WineSource? source,
  }) {
    return WineBottle(
      name: name ?? this.name,
      winery: winery ?? this.winery,
      year: year ?? this.year,
      notes: notes ?? this.notes,
      country: country ?? this.country,
      dateAdded: dateAdded ?? this.dateAdded,
      dateDrunk: dateDrunk ?? this.dateDrunk,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      isDrunk: isDrunk ?? this.isDrunk,
      ownerId: ownerId ?? this.ownerId,
      isForTrade: isForTrade ?? this.isForTrade,
      metadata: metadata ?? this.metadata,
      source: source ?? this.source,
    );
  }

  factory WineBottle.fromJson(Map<String, dynamic> json) {
    return WineBottle(
      name: json['name'],
      winery: json['winery'],
      year: json['year'],
      notes: json['notes'],
      country: json['country'],
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'])
          : null,
      dateDrunk: json['dateDrunk'] != null
          ? DateTime.parse(json['dateDrunk'])
          : null,
      imagePath: json['imagePath'],
      type: json['type'] != null ? WineType.values[json['type']] : null,
      rating: json['rating']?.toDouble(),
      price: json['price']?.toDouble(),
      isFavorite: json['isFavorite'] ?? false,
      isDrunk: json['isDrunk'] ?? false,
      ownerId: json['ownerId'],
      isForTrade: json['isForTrade'] == true,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      source: json['source'] != null 
          ? WineSource.values[json['source']] 
          : WineSource.fridge,
    );
  }

  // Also update toJson to ensure we're saving boolean correctly
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'winery': winery,
      'year': year,
      'notes': notes,
      'country': country,
      'dateAdded': dateAdded?.toIso8601String(),
      'dateDrunk': dateDrunk?.toIso8601String(),
      'imagePath': imagePath,
      'type': type?.index,
      'rating': rating,
      'price': price,
      'isFavorite': isFavorite,
      'isDrunk': isDrunk,
      'ownerId': ownerId,
      'isForTrade': isForTrade,
      'metadata': metadata,
      'source': source.index,
    };
  }
}