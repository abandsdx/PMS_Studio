import 'dart:async';
import 'dart:math';
import 'api_service.dart';
import 'main.dart'; // Import to get NavigationOrder enum
import 'models/location_model.dart';
import 'models/robot_info_model.dart';
import 'models/report_model.dart';

class NavigationController {
  final ApiService api;
  final Function(String) log;

  NavigationController(this.api, this.log);

  Future<TaskReport> startNavigation(
    String sn,
    String selectedMapName, {
    required NavigationOrder navigationOrder,
    required bool Function() isStopping,
  }) async {
    final taskStartTime = DateTime.now();
    final missionId =
        "MCS-${taskStartTime.year}${_twoDigits(taskStartTime.month)}${_twoDigits(taskStartTime.day)}${_twoDigits(taskStartTime.hour)}${_twoDigits(taskStartTime.minute)}${_twoDigits(taskStartTime.second)}";
    final uId = (Random().nextInt(9000) + 1000).toString();

    final List<NavigationLeg> navigationLegs = [];
    String status = "Failed"; // Default status

    try {
      log("啟動 New Task...");
      await api.newTask(sn, missionId, uId);

      if (isStopping()) throw Exception("Task stopped by user before starting.");

      log("抓取 Locations...");
      final List<MapInfo> allMaps = await api.getLocations();
      final MapInfo selectedMap = allMaps.firstWhere(
        (map) => map.mapName == selectedMapName,
        orElse: () => throw Exception("Map '$selectedMapName' not found"),
      );

      // Create a mutable copy of the locations list to be modified.
      final List<String> rLocationNames = List.from(selectedMap.rLocations);

      switch (navigationOrder) {
        case NavigationOrder.sorted:
          rLocationNames.sort();
          log("導航順序: 已排序");
          break;
        case NavigationOrder.random:
          rLocationNames.shuffle();
          log("導航順序: 隨機");
          break;
        // No default case needed as all enum values are handled.
      }

      log("rLocations: ${rLocationNames.join(', ')}");

      for (String locationName in rLocationNames) {
        if (isStopping()) {
          log("任務已被使用者手動停止。");
          status = "Stopped by user";
          await api.stopMovement(sn, missionId, uId);
          break;
        }

        final legStartTime = DateTime.now();
        log("導航至: $locationName (開始時間: ${legStartTime.toIso8601String()})");
        await api.navigation(
            missionId: missionId, uId: uId, sn: sn, locationName: locationName);

        String moveStatus = "";
        RobotInfo? finalRobotInfo;
        while (moveStatus != "10") {
          if (isStopping()) break;
          await Future.delayed(const Duration(seconds: 2));
          finalRobotInfo = await api.getRobotMoveStatus(sn);
          moveStatus = finalRobotInfo.moveStatus;
        }

        if (isStopping()) {
           log("任務在 '$locationName' 中途被使用者手動停止。");
           status = "Stopped by user";
           await api.stopMovement(sn, missionId, uId);
           break;
        }

        final legEndTime = DateTime.now();
        log("已到達 $locationName (結束時間: ${legEndTime.toIso8601String()})");
        navigationLegs.add(NavigationLeg(
          targetLocation: locationName,
          startTime: legStartTime,
          endTime: legEndTime,
          endWifiSsid: finalRobotInfo?.wifiSsid,
          endWifiRssi: finalRobotInfo?.wifiRssi,
        ));
      }

      if (status != "Stopped by user") {
        log("所有 rLocations 導航完成，開始完成任務...");
        await api.completeTask(sn, missionId, uId);
        log("任務完成!");
        status = "Success";
      }
    } catch (e) {
      log("導航任務失敗: $e");
      status = "Failed: $e";
    }

    final taskEndTime = DateTime.now();
    return TaskReport(
      robotSn: sn,
      mapName: selectedMapName,
      missionId: missionId,
      taskStartTime: taskStartTime,
      taskEndTime: taskEndTime,
      status: status,
      navigationLegs: navigationLegs,
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
