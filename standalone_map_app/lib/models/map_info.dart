import 'dart:convert';

/// Represents all the necessary information about a single map.
class MapInfo {
  final String mapName;
  final String mapUuid;
  final String floor;
  final List<String> rLocations;
  final String mapImage;
  final List<double> mapOrigin;

  MapInfo({
    required this.mapName,
    required this.mapUuid,
    required this.floor,
    required this.rLocations,
    required this.mapImage,
    required this.mapOrigin,
  });

  /// Creates a [MapInfo] object from a JSON map.
  factory MapInfo.fromJson(Map<String, dynamic> json) => MapInfo(
        mapName: json["mapName"] ?? '',
        mapUuid: json["mapUuid"] ?? '',
        floor: json["floor"] ?? '',
        rLocations: json["rLocations"] == null
            ? []
            : List<String>.from(json["rLocations"].map((x) => x)),
        mapImage: json["mapImage"] ?? '',
        mapOrigin: json["mapOrigin"] == null
            ? []
            : List<double>.from(json["mapOrigin"].map((x) => x.toDouble())),
      );

  /// Converts a [MapInfo] object to a JSON map.
  Map<String, dynamic> toJson() => {
        "mapName": mapName,
        "mapUuid": mapUuid,
        "floor": floor,
        "rLocations": List<dynamic>.from(rLocations.map((x) => x)),
        "mapImage": mapImage,
        "mapOrigin": List<dynamic>.from(mapOrigin.map((x) => x)),
      };
}