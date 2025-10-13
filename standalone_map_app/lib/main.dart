import 'package:flutter/material.dart';
import 'package:standalone_map_app/models/map_data.dart';
import 'package:standalone_map_app/utils/api_service.dart';
import 'package:standalone_map_app/widgets/map_tracking_dialog.dart';
import 'models/field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Standalone Map App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  List<Field> _fields = [];
  Field? _selectedField;
  MapData? _selectedMap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    try {
      final fields = await _apiService.getFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching fields: $e')),
      );
    }
  }

  void _showMapDialog() {
    if (_selectedMap != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return MapTrackingDialog(
            mapInfo: _selectedMap!,
            robotUuid: "mock-robot-123",
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Viewer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<Field>(
                    value: _selectedField,
                    hint: const Text('Select a Field'),
                    isExpanded: true,
                    items: _fields.map((Field field) {
                      return DropdownMenuItem<Field>(
                        value: field,
                        child: Text(field.fieldName),
                      );
                    }).toList(),
                    onChanged: (Field? newValue) {
                      setState(() {
                        _selectedField = newValue;
                        _selectedMap = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_selectedField != null)
                    DropdownButton<MapData>(
                      value: _selectedMap,
                      hint: const Text('Select a Map'),
                      isExpanded: true,
                      items: _selectedField!.maps.map((MapData map) {
                        return DropdownMenuItem<MapData>(
                          value: map,
                          child: Text(map.mapName),
                        );
                      }).toList(),
                      onChanged: (MapData? newValue) {
                        setState(() {
                          _selectedMap = newValue;
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Show Map'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _selectedMap != null ? _showMapDialog : null,
                  ),
                ],
              ),
            ),
    );
  }
}
