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
  final TextEditingController _apiKeyController = TextEditingController();
  List<Field> _fields = [];
  Field? _selectedField;
  MapData? _selectedMap;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to rebuild the widget when the text changes to update button state.
    _apiKeyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _fetchFields() async {
    final apiKey = _apiKeyController.text;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API Key')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _fields = [];
      _selectedField = null;
      _selectedMap = null;
    });

    try {
      final fields = await _apiService.getFields(apiKey);
      setState(() {
        _fields = fields;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching fields: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    // Determine if the button should be enabled.
    final bool isButtonEnabled = _apiKeyController.text.isNotEmpty && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Viewer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API Key here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isButtonEnabled ? _fetchFields : null,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Fetch Fields'),
            ),
            const SizedBox(height: 20),
            if (_fields.isNotEmpty) ...[
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
          ],
        ),
      ),
    );
  }
}
