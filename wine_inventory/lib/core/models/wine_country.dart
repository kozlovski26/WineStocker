class WineCountry {
  final String name;
  final String flag;
  
  const WineCountry(this.name, this.flag);
  
  static const List<WineCountry> topWineCountries = [
    WineCountry('France', '🇫🇷'),
    WineCountry('Italy', '🇮🇹'),
    WineCountry('Spain', '🇪🇸'),
    WineCountry('Israel', '🇮🇱'),
    WineCountry('United States', '🇺🇸'),
    WineCountry('Argentina', '🇦🇷'),
    WineCountry('Australia', '🇦🇺'),
    WineCountry('Germany', '🇩🇪'),
    WineCountry('South Africa', '🇿🇦'),
    WineCountry('Chile', '🇨🇱'),
    WineCountry('Portugal', '🇵🇹'),
    WineCountry('New Zealand', '🇳🇿'),
    WineCountry('Austria', '🇦🇹'),
    WineCountry('Greece', '🇬🇷'),
    WineCountry('Hungary', '🇭🇺'),
    WineCountry('Canada', '🇨🇦'),
    WineCountry('Switzerland', '🇨🇭'),
    WineCountry('Croatia', '🇭🇷'),
    WineCountry('Uruguay', '🇺🇾'),
    WineCountry('Moldova', '🇲🇩'),
    WineCountry('Romania', '🇷🇴'),
  ];

  static String? getFlagForCountry(String? countryName) {
    if (countryName == null) return null;
    final country = topWineCountries.firstWhere(
      (c) => c.name.toLowerCase() == countryName.toLowerCase(),
      orElse: () => WineCountry(countryName, '🍷'),
    );
    return country.flag;
  }
} 