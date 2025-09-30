// Represents a single map's details.
class MapInfo {
  final String? mapName;
  final String mapUuid;
  final String floor;
  final List<String> rLocations;
  final Map<String, List<double>> coordinates;
  final String mapImage;
  final List<double> mapOrigin;

  MapInfo({
    this.mapName,
    required this.mapUuid,
    required this.floor,
    required this.rLocations,
    required this.coordinates,
    required this.mapImage,
    required this.mapOrigin,
  });

  factory MapInfo.fromJson(Map<String, dynamic> json) {
    final rLocationsData = json['rLocations'];
    final locations = (rLocationsData is List)
        ? List<String>.from(rLocationsData)
        : <String>[];

    final coordinatesData = json['coordinates'];
    final coordinatesMap = <String, List<double>>{};
    if (coordinatesData is Map) {
      coordinatesData.forEach((key, value) {
        if (value is List) {
          coordinatesMap[key] = List<double>.from(value.map((e) => (e as num).toDouble()));
        }
      });
    }

    final mapOriginData = json['mapOrigin'];
    final mapOriginList = (mapOriginData is List)
        ? List<double>.from(mapOriginData.map((e) => (e as num).toDouble()))
        : <double>[];

    return MapInfo(
      mapName: json['mapName'],
      mapUuid: json['mapUuid'] ?? '',
      floor: json['floor'] ?? '',
      rLocations: locations,
      coordinates: coordinatesMap,
      mapImage: json['mapImage'] ?? '',
      mapOrigin: mapOriginList,
    );
  }
}

// Represents a top-level field object from the API, which contains maps.
class Field {
  final String fieldId;
  final String fieldName;
  final List<MapInfo> maps;

  Field({
    required this.fieldId,
    required this.fieldName,
    required this.maps,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    final mapsData = json['maps'];
    final mapsList = (mapsData is List)
        ? mapsData
            .map((mapJson) => MapInfo.fromJson(mapJson as Map<String, dynamic>))
            .toList()
        : <MapInfo>[];

    return Field(
      fieldId: json['fieldId'] ?? '',
      fieldName: json['fieldName'] ?? 'Unnamed Field',
      maps: mapsList,
    );
  }
}
