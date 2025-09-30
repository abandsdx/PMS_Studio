# Standalone Map Visualization

This Flutter project is a standalone extraction of the map visualization feature from the `PMS_Flutter-main` application. Its purpose is to demonstrate the map rendering and real-time robot tracking functionality in an isolated, self-contained environment.

## Purpose

The original project had its map visualization logic tightly coupled with its overall application state, API services, and specific data models. This standalone version was created to:

1.  **Isolate the Map Feature**: Separate the map UI and logic from the parent application.
2.  **Demonstrate Core Functionality**: Clearly show how the map is rendered and how robot coordinates are plotted.
3.  **Enable Independent Development**: Allow for easier testing, debugging, and modification of the map feature without running the full original application.
4.  **Replace Dependencies**: Substitute server-fetched data and live MQTT streams with local, mock data to make the project runnable by anyone, anywhere.

## How to Run

1.  Ensure you have the Flutter SDK installed.
2.  Navigate to the `standalone_map_app` directory.
3.  Install dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the application:
    ```bash
    flutter run
    ```

## Project Structure

-   `lib/`
    -   `main.dart`: The main application entry point. Contains a simple UI to launch the map dialog.
    -   `config/`:
        -   `mock_config.dart`: Provides all necessary mock data, such as map details, image URLs, and fixed point coordinates.
    -   `models/`:
        -   `map_info.dart`: The data model for a map.
    -   `utils/`:
        -   `mqtt_service.dart`: A modified version of the original MQTT service. It can be configured to connect to a real broker or, by default, generate **mock robot position data** to simulate movement.
    -   `widgets/`:
        -   `map_tracking_dialog.dart`: The core UI component. This dialog displays the map, fixed points, and the robot's trail based on data from the `MqttService`.
-   `pubspec.yaml`: Defines project dependencies, including `flutter` and `mqtt_client`.

## How It Works

The application is designed to be simple and self-contained:

1.  **Launching the Map**: The `HomePage` in `main.dart` has a button that, when pressed, creates and shows a `MapTrackingDialog`.
2.  **Mock Configuration**: The dialog is instantiated using a `MapInfo` object provided by the static `MockConfig.mockMap` class. This object contains all the necessary information: the map image name, the list of points to display, and the map's origin coordinates.
3.  **Mock Real-time Data**: When the `MapTrackingDialog` is initialized, it calls the `MqttService`. The service is configured by default (`_useMockData = true`) to start a mock data generator. This generator uses a `Timer` to periodically create new `Point` objects and add them to a stream, simulating the path of a robot moving in a square.
4.  **Rendering**: The `MapTrackingDialog` listens to the `MqttService.positionStream`. As new points arrive, it adds them to a list of trail points and triggers a repaint of the `MapAndRobotPainter`, which draws the updated path on the screen.
5.  **Coordinate Transformation**: The `MapAndRobotPainter` uses the map's origin coordinates and a fixed resolution (0.05 meters/pixel) to convert the incoming world coordinates (from the MQTT service) into pixel coordinates that can be drawn correctly on the map image.