class CountryData {
  static const List<String> popularCountries = [
    'China', 'Vietnam', 'Mongolia', 'Japan', 'USA', 'Germany',
    'France', 'Russia', 'Korea', 'Taiwan', 'Thailand', 'Indonesia',
  ];

  static const List<String> allCountries = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
    'Austria', 'Bangladesh', 'Belgium', 'Bolivia', 'Brazil',
    'Cambodia', 'Canada', 'Chile', 'China', 'Colombia',
    'Czech Republic', 'Denmark', 'Egypt', 'Ethiopia', 'Finland',
    'France', 'Germany', 'Ghana', 'Greece', 'Hungary',
    'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland',
    'Israel', 'Italy', 'Japan', 'Jordan', 'Kazakhstan',
    'Kenya', 'Korea', 'Kuwait', 'Laos', 'Lebanon',
    'Malaysia', 'Mexico', 'Mongolia', 'Morocco', 'Myanmar',
    'Nepal', 'Netherlands', 'New Zealand', 'Nigeria', 'Norway',
    'Pakistan', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Romania', 'Russia', 'Saudi Arabia', 'South Africa', 'Spain',
    'Sri Lanka', 'Sweden', 'Switzerland', 'Syria', 'Taiwan',
    'Thailand', 'Turkey', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'USA', 'Uzbekistan', 'Venezuela', 'Vietnam',
    'Yemen', 'Zambia', 'Zimbabwe',
  ];

  static List<String> filterCountries(String query) {
    if (query.isEmpty) return allCountries;
    return allCountries
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
