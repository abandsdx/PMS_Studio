import '../models/map_info.dart';

/// A class to provide mock configuration data for the standalone map app.
/// In a real application, this data would likely come from a server or a config file.
class MockConfig {
  /// The base URL where the map images are hosted.
  static const String mapBaseUrl = 'http://64.110.100.118:8001';

  /// A hardcoded map of all possible named locations and their world coordinates.
  /// The key is the location name (e.g., "R0101") and the value is a list
  /// containing the [x, y] coordinates in meters.
  static const Map<String, List<double>> allPossiblePoints = {
    "EL0101": [0.17, -0.18],
    "EL0102": [0.18, -1.18],
    "MA01": [6.22, -9.53],
    "R0101": [-1.29, -7.71],
    "R0102": [-1.29, -5.44],
    "R0103": [0.1, -6.09],
    "R0104": [-8.41, 6.96],
    "SL0101": [0.19, -2.94],
    "SL0102": [0.15, -2.44],
    "SL0103": [-8.04, 7.19],
    "VM0101": [-0.81, 4.08],
    "WL0101": [5.24, -9.66],
    "XL0101": [5.53, -9.99],
    "R0301": [-1.3, -2.0],
    "R0302": [-1.3, -3.0],
    "R0303": [-1.3, -4.0],
  };

  /// A mock [MapInfo] object for demonstration purposes.
  static final MapInfo mockMap = MapInfo(
    mapName: "1F",
    mapUuid: "mock-map-uuid",
    floor: "1",
    // These are the locations that will be drawn on the map.
    rLocations: ["R0101", "R0102", "R0103", "SL0101", "SL0102", "EL0101", "EL0102"],
    mapImage: "nuwa_office_1f.pgm",
    // This origin is crucial for correctly transforming coordinates.
    mapOrigin: [23.45, 12.34], // Example values, replace with actual origin if known
  );

  /// Another mock [MapInfo] object for a different floor.
  static final MapInfo mockMap2 = MapInfo(
      mapName: "3F",
      mapUuid: "mock-map-uuid-3f",
      floor: "3",
      rLocations: ["R0301", "R0302", "R0303"],
      mapImage: "nuwa_office_3f.pgm",
      mapOrigin: [25.0, 15.0] // Different origin for a different map
  );
}