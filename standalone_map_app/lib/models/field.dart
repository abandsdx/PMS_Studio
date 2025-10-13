import 'map_data.dart';

class Field {
  final String fieldId;
  final String fieldName;
  final List<MapData> maps;

  Field({
    required this.fieldId,
    required this.fieldName,
    required this.maps,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    var list = json['maps'] as List;
    List<MapData> mapsList = list.map((i) => MapData.fromJson(i)).toList();
    return Field(
      fieldId: json['fieldId'],
      fieldName: json['fieldName'],
      maps: mapsList,
    );
  }
}
