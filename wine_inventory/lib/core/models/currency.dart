enum Currency {
  USD,
  ILS,
  EUR,
  GBP,
  JPY;

  String get symbol {
    switch (this) {
      case Currency.USD:
        return '\$';
      case Currency.ILS:
        return '₪';
      case Currency.EUR:
        return '€';
      case Currency.GBP:
        return '£';
      case Currency.JPY:
        return '¥';
    }
  }

  String get name {
    switch (this) {
      case Currency.USD:
        return 'US Dollar';
      case Currency.ILS:
        return 'Israeli Shekel';
      case Currency.EUR:
        return 'Euro';
      case Currency.GBP:
        return 'British Pound';
      case Currency.JPY:
        return 'Japanese Yen';
    }
  }
} 