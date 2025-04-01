class WineGrape {
  final String name;
  final String type; // red, white, or both

  const WineGrape(this.name, this.type);

  static const List<WineGrape> commonGrapes = [
    // Red Grapes
    WineGrape('Cabernet Sauvignon', 'red'),
    WineGrape('Merlot', 'red'),
    WineGrape('Pinot Noir', 'red'),
    WineGrape('Syrah/Shiraz', 'red'),
    WineGrape('Malbec', 'red'),
    WineGrape('Sangiovese', 'red'),
    WineGrape('Tempranillo', 'red'),
    WineGrape('Grenache', 'red'),
    WineGrape('Nebbiolo', 'red'),
    WineGrape('Zinfandel', 'red'),
    
    // White Grapes
    WineGrape('Chardonnay', 'white'),
    WineGrape('Sauvignon Blanc', 'white'),
    WineGrape('Riesling', 'white'),
    WineGrape('Pinot Grigio', 'white'),
    WineGrape('Moscato', 'white'),
    WineGrape('Gewürztraminer', 'white'),
    WineGrape('Viognier', 'white'),
    WineGrape('Chenin Blanc', 'white'),
    WineGrape('Semillon', 'white'),
    WineGrape('Albariño', 'white'),
  ];

  static List<WineGrape> getGrapesByType(String type) {
    return commonGrapes.where((grape) => grape.type == type).toList();
  }
} 