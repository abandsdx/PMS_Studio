class MapData {
  final String mapName;
  final String mapUuid;
  final String floor;
  final List<String> rLocations;
  final Map<String, List<double>> coordinates;
  final String mapImage;
  final List<double> mapOrigin;

  MapData({
    required this.mapName,
    required this.mapUuid,
    required this.floor,
    required this.rLocations,
    required this.coordinates,
    required this.mapImage,
    required this.mapOrigin,
  });

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      mapName: json['mapName'],
      mapUuid: json['mapUuid'],
      floor: json['floor'],
      rLocations: List<String>.from(json['rLocations']),
      coordinates: (json['coordinates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toDouble()).toList(),
        ),
      ),
      mapImage: json['mapImage'],
      mapOrigin: (json['mapOrigin'] as List<dynamic>).map((e) => e.toDouble()).toList(),
    );
  }
}
