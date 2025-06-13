import 'package:flutter_test/flutter_test.dart';
import 'package:schengen/models/schengen_detector.dart';

void main() {
  group('SchengenDetector', () {
    final detector = SchengenDetector();

    test('should correctly identify locations within Schengen zone', () async {
      // Test cases: (latitude, longitude, expected result, country name for clarity)
      final inSchengenCases = [
        (48.2082, 16.3738, true, 'Vienna, Austria'), // Austria
        (50.8503, 4.3517, true, 'Brussels, Belgium'), // Belgium
        (42.6977, 23.3219, true, 'Sofia, Bulgaria'), // Bulgaria
        (45.8150, 15.9819, true, 'Zagreb, Croatia'), // Croatia
        (50.0755, 14.4378, true, 'Prague, Czech Republic'), // Czech Republic
        (55.6761, 12.5683, true, 'Copenhagen, Denmark'), // Denmark
        (59.4370, 24.7536, true, 'Tallinn, Estonia'), // Estonia
        (60.1699, 24.9384, true, 'Helsinki, Finland'), // Finland
        (48.8566, 2.3522, true, 'Paris, France'), // France
        (52.5200, 13.4050, true, 'Berlin, Germany'), // Germany
        (37.9838, 23.7275, true, 'Athens, Greece'), // Greece
        (47.4979, 19.0402, true, 'Budapest, Hungary'), // Hungary
        (64.1466, -21.9426, true, 'Reykjavik, Iceland'), // Iceland
        (41.9028, 12.4964, true, 'Rome, Italy'), // Italy
        (56.9496, 24.1052, true, 'Riga, Latvia'), // Latvia
        (47.1410, 9.5239, true, 'Vaduz, Liechtenstein'), // Liechtenstein
        (54.6872, 25.2797, true, 'Vilnius, Lithuania'), // Lithuania
        (49.8153, 6.1296, true, 'Luxembourg City, Luxembourg'), // Luxembourg
        (35.8989, 14.5146, true, 'Valletta, Malta'), // Malta
        (52.3676, 4.9041, true, 'Amsterdam, Netherlands'), // Netherlands
        (59.9139, 10.7522, true, 'Oslo, Norway'), // Norway
        (52.2297, 21.0122, true, 'Warsaw, Poland'), // Poland
        (38.7223, -9.1393, true, 'Lisbon, Portugal'), // Portugal
        (44.4268, 26.1025, true, 'Bucharest, Romania'), // Romania
        (48.1486, 17.1077, true, 'Bratislava, Slovakia'), // Slovakia
        (46.0569, 14.5058, true, 'Ljubljana, Slovenia'), // Slovenia
        (40.4168, -3.7038, true, 'Madrid, Spain'), // Spain
        (59.3293, 18.0686, true, 'Stockholm, Sweden'), // Sweden
        (46.9480, 7.4474, true, 'Bern, Switzerland'), // Switzerland
      ];

      for (var testCase in inSchengenCases) {
        expect(
          await detector.isInSchengenZone(testCase.$1, testCase.$2),
          testCase.$3,
          reason:
              '${testCase.$4} should be ${testCase.$3 ? 'in' : 'out of'} Schengen.',
        );
      }
    });

    test('should correctly identify locations outside Schengen zone', () async {
      final outOfSchengenCases = [
        (51.5074, -0.1278, false, 'London, United Kingdom'), // UK
        (39.9334, 32.8597, false, 'Ankara, Turkey'), // Turkey
        (34.6937, 135.5023, false, 'Osaka, Japan'), // Japan
        (40.7128, -74.0060, false, 'New York, USA'), // USA
        (55.7558, 37.6173, false, 'Moscow, Russia'), // Russia
        (33.8688, 151.2093, false, 'Sydney, Australia'), // Australia
        (-22.9068, -43.1729, false, 'Rio de Janeiro, Brazil'), // Brazil
        (1.3521, 103.8198, false, 'Singapore'), // Singapore
        (31.2304, 121.4737, false, 'Shanghai, China'), // China
        (19.0760, 72.8777, false, 'Mumbai, India'), // India
        (30.0444, 31.2357, false, 'Cairo, Egypt'), // Egypt
        (43.6532, -79.3832, false, 'Toronto, Canada'), // Canada
        (35.6895, 51.3890, false, 'Tehran, Iran'), // Iran
        (
          53.3498,
          -6.2603,
          false,
          'Dublin, Ireland',
        ), // Ireland (not in Schengen)
        (34.0522, -118.2437, false, 'Los Angeles, USA'), // USA
      ];

      for (var testCase in outOfSchengenCases) {
        expect(
          await detector.isInSchengenZone(testCase.$1, testCase.$2),
          testCase.$3,
          reason:
              '${testCase.$4} should be ${testCase.$3 ? 'in' : 'out of'} Schengen.',
        );
      }
    });

    test(
      'should handle edge cases or disputed territories if applicable (example)',
      () async {
        // Example: A point very close to a border, or a region with complex status
        // This depends on the precision of country_coder and the specific data it uses.
        // For now, we'll use a known point.
        // Gibraltar (disputed, UK territory, not Schengen)
        expect(
          await detector.isInSchengenZone(36.1408, -5.3536),
          false,
          reason: 'Gibraltar should be out of Schengen.',
        );
        // A point in the sea, far from any land (should be false)
        expect(
          await detector.isInSchengenZone(0.0, 0.0),
          false,
          reason: 'Point (0,0) in Atlantic Ocean should be out of Schengen.',
        );
      },
    );
  });
}
