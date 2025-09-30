// Represents one leg of the navigation journey.
class NavigationLeg {
  final String targetLocation;
  final DateTime startTime;
  final DateTime endTime;
  final String? endWifiSsid;
  final int? endWifiRssi;

  NavigationLeg({
    required this.targetLocation,
    required this.startTime,
    required this.endTime,
    this.endWifiSsid,
    this.endWifiRssi,
  });

  Duration get duration => endTime.difference(startTime);
}

// Represents the final report for a completed navigation task.
class TaskReport {
  final String robotSn;
  final String mapName;
  final String missionId;
  final DateTime taskStartTime;
  final DateTime taskEndTime;
  final String status; // e.g., "Success", "Failed", "Cancelled"
  final List<NavigationLeg> navigationLegs;

  TaskReport({
    required this.robotSn,
    required this.mapName,
    required this.missionId,
    required this.taskStartTime,
    required this.taskEndTime,
    required this.status,
    required this.navigationLegs,
  });

  Duration get totalDuration => taskEndTime.difference(taskStartTime);
}
