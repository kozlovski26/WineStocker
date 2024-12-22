import 'package:wine_inventory/core/models/wine_type.dart';

class WineBottle {
  String? name;
  String? year;
  String? notes;
  DateTime? dateAdded;
  DateTime? dateDrunk;
  String? imagePath;
  WineType? type;
  double? rating;
  double? price; // Added price field
  bool isFavorite;
  bool isDrunk;
  String? ownerId; // Added owner ID for trading feature
  bool isForTrade; // Added trade status

  WineBottle({
    this.name,
    this.year,
    this.notes,
    this.dateAdded,
    this.dateDrunk,
    this.imagePath,
    this.type,
    this.rating,
    this.price, // Added price
    this.isFavorite = false,
    this.isDrunk = false,
    this.ownerId,
    this.isForTrade = false,
  });

  bool get isEmpty => name == null && imagePath == null;

  // In wine_bottle.dart

factory WineBottle.fromJson(Map<String, dynamic> json) {

    return WineBottle(
      name: json['name'],
      year: json['year'],
      notes: json['notes'],
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
    );
  }

  // Also update toJson to ensure we're saving boolean correctly
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'notes': notes,
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
    };
  }
}