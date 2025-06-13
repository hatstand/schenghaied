import 'package:country_coder/country_coder.dart';
import 'package:flutter/foundation.dart' show compute;

class SchengenDetector {
  static const schengenCountries = LocationSet(
    include: [
      "AT", // Austria
      "BE", // Belgium
      "BG", // Bulgaria
      "HR", // Croatia
      "CZ", // Czech Republic
      "DK", // Denmark
      "EE", // Estonia
      "FI", // Finland
      "FR", // France
      "DE", // Germany
      "GR", // Greece
      "HU", // Hungary
      "IS", // Iceland
      "IT", // Italy
      "LV", // Latvia
      "LI", // Liechtenstein
      "LT", // Lithuania
      "LU", // Luxembourg
      "MT", // Malta
      "NL", // Netherlands
      "NO", // Norway
      "PL", // Poland
      "PT", // Portugal
      "RO", // Romania
      "SK", // Slovakia
      "SI", // Slovenia
      "ES", // Spain
      "SE", // Sweden
      "CH", // Switzerland
    ],
  );

  Future<bool> isInSchengenZone(double lat, double lng) async {
    CountryCoder.instance.load(await compute(CountryCoder.prepareData, null));
    LocationMatcher matcher = LocationMatcher();
    return matcher(lng, lat, schengenCountries);
  }
}
