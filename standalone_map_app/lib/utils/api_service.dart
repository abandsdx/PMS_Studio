import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/field.dart';

class ApiService {
  static const String baseUrl = 'http://152.69.194.121:8000';

  Future<List<Field>> getFields() async {
    try {
      // First, trigger a refresh
      await http.post(Uri.parse('$baseUrl/trigger-refresh'));

      // Then, get the field map data
      final response = await http.get(Uri.parse('$baseUrl/field-map'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Field.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fields');
      }
    } catch (e) {
      throw Exception('Error fetching fields: $e');
    }
  }
}
