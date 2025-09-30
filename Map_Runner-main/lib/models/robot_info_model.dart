class RobotInfo {
  final String id;
  final String sn;
  final bool batteryCharging;
  final int battery;
  final String moveStatus;
  final String product;
  final String model;
  final Map<String, dynamic> middleLayer;
  final String foregroundApp;
  final Map<String, dynamic> hardware;
  final Map<String, dynamic> deliverior;
  final String chassisUuid;
  final String chassisVersion;
  final String? mapUuid;
  final String? location;
  final String? imageVersion;
  final String? extendRobotSn;
  final String? extendRobotIp;
  final bool extendRobotConnected;
  final String? wifiSsid;
  final int? wifiRssi;
  final int timestamp;
  final String createdAt;
  final String updatedAt;
  final int connStatus;
  final int licenseEndTime;
  final bool supportMCS;
  final String hardwareStatus;
  final String deliveriorStatus;

  RobotInfo({
    required this.id,
    required this.sn,
    required this.batteryCharging,
    required this.battery,
    required this.moveStatus,
    required this.product,
    required this.model,
    required this.middleLayer,
    required this.foregroundApp,
    required this.hardware,
    required this.deliverior,
    required this.chassisUuid,
    required this.chassisVersion,
    this.mapUuid,
    this.location,
    this.imageVersion,
    this.extendRobotSn,
    this.extendRobotIp,
    required this.extendRobotConnected,
    this.wifiSsid,
    this.wifiRssi,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.connStatus,
    required this.licenseEndTime,
    required this.supportMCS,
    required this.hardwareStatus,
    required this.deliveriorStatus,
  });

  factory RobotInfo.fromJson(Map<String, dynamic> json) {
    return RobotInfo(
      id: json['_id'] ?? '',
      sn: json['sn'] ?? '',
      batteryCharging: json['batteryCharging'] ?? false,
      battery: json['battery'] ?? 0,
      moveStatus: json['moveStatus']?.toString() ?? '',
      product: json['product'] ?? '',
      model: json['model'] ?? '',
      middleLayer: json['middleLayer'] as Map<String, dynamic>? ?? {},
      foregroundApp: json['foregroundApp'] ?? '',
      hardware: json['hardware'] as Map<String, dynamic>? ?? {},
      deliverior: json['deliverior'] as Map<String, dynamic>? ?? {},
      chassisUuid: json['chassisUuid'] ?? '',
      chassisVersion: json['chassisVersion'] ?? '',
      mapUuid: json['mapUuid'],
      location: json['location'],
      imageVersion: json['imageVersion'],
      extendRobotSn: json['extendRobotSn'],
      extendRobotIp: json['extendRobotIp'],
      extendRobotConnected: json['extendRobotConnected'] ?? false,
      wifiSsid: json['wifiSsid'],
      wifiRssi: json['wifiRssi'],
      timestamp: json['timestamp'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      connStatus: json['connStatus'] ?? 0,
      licenseEndTime: json['licenseEndTime'] ?? 0,
      supportMCS: json['supportMCS'] ?? false,
      hardwareStatus: json['hardwareStatus'] ?? '',
      deliveriorStatus: json['deliveriorStatus'] ?? '',
    );
  }
}
