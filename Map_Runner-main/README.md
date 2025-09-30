# Map Runner - Robot Navigation Test App

## Overview

Map Runner is a Flutter-based utility application designed to test and control robot navigation functionalities. It provides a simple user interface to connect to a robot's API, fetch available maps and robots, and command a specific robot to navigate a series of locations on a selected map.

The application serves as a testing and debugging tool for robot navigation tasks.

## Features

- **Dynamic API Key Configuration**: Allows the user to input and apply an API key at runtime.
- **Dynamic Data Fetching**: Fetches lists of available robots and maps from the backend server.
- **Dropdown Selection**: Allows for easy selection of the target robot and map from dropdown menus.
- **Automated Navigation Sequence**:
  - Initiates a "New Task" with the API.
  - Iterates through all predefined locations (`rLocations`) on the selected map.
  - Sends a "Navigation" command for each location.
  - Polls the robot's `moveStatus` to wait for its arrival at each location.
  - Completes the task once all locations have been visited.
- **Real-time Logging**: Displays a detailed log of all operations in a scrollable, copyable text view.
- **Robust API Handling**:
  - Gracefully handles API responses where map data is still being processed, with an automatic retry mechanism.
  - Safely parses potentially `null` or malformed data from the API to prevent crashes.
- **HTML Report Generation**: After a task is completed (successfully or not), a detailed HTML report can be generated and shared, containing a task summary and a table of timing for each navigation leg.

## How to Use

1.  **Launch the Application**.
2.  **Set the API Key**:
    -   Enter your `Basic` authentication token into the "輸入 API 金鑰" (Enter API Key) text field.
    -   Press the "套用" (Apply) button.
    -   The application will use this key to fetch lists of available robots and maps. Check the log window for success or failure messages.
3.  **Select a Robot**:
    -   Choose a robot from the "選擇機器人 SN" (Select Robot SN) dropdown menu.
4.  **Select a Map**:
    -   Choose a map from the "選擇 MapName" (Select MapName) dropdown menu.
5.  **Start Navigation**:
    -   Press the "開始循環導航" (Start Loop Navigation) button.
    -   The robot will begin its navigation sequence.
6.  **Monitor Progress**:
    -   Observe the log window for real-time updates on the robot's progress.
7.  **Generate Report**:
    -   After the navigation task is finished, the "產生報告" (Generate Report) button will become enabled.
    -   Click it to generate and share a detailed HTML report of the task.

## Project Structure

The project follows a standard Flutter application structure, with all Dart source code located in the `lib/` directory.

```
lib/
├── main.dart                  # Main application entry point and UI for the navigation page.
├── api_service.dart           # Handles all HTTP requests to the backend APIs.
├── navigation_controller.dart # Contains the core business logic for the navigation sequence.
├── report_generator.dart      # Contains logic to generate the HTML report.
│
├── models/
│   ├── location_model.dart    # Data models for Fields and Maps.
│   ├── robot_info_model.dart  # Data model for robot status.
│   └── report_model.dart      # Data models for the navigation report.
│
└── widgets/
    └── log_console.dart       # A simple, reusable widget for displaying logs.
```
