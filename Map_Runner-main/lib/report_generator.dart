import 'package:intl/intl.dart';
import 'models/report_model.dart';

class ReportGenerator {
  static String generateFilename(TaskReport report) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    // Sanitize mapName to be used in a filename
    final sanitizedMapName =
        report.mapName.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
    return '${report.robotSn}_${sanitizedMapName}_$timestamp.html';
  }

  static String generateHtmlReport(TaskReport report) {
    final summaryHtml = _generateSummaryHtml(report);
    final legsHtml = _generateLegsTableHtml(report.navigationLegs);

    return """
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8">
    <title>導航任務報告</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; padding: 20px; color: #333; }
        .container { max-width: 800px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1, h2 { border-bottom: 2px solid #eee; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: 150px 1fr; gap: 10px 20px; margin-bottom: 20px; }
        .summary strong { font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ccc; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>導航任務報告</h1>
        <p><strong>產生時間:</strong> ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}</p>

        <h2>任務摘要</h2>
        $summaryHtml

        <h2>導航路徑詳細記錄</h2>
        $legsHtml
    </div>
</body>
</html>
""";
  }

  static String _generateSummaryHtml(TaskReport report) {
    final totalDuration = _formatDuration(report.totalDuration);
    final statusColor = report.status.contains("Success") ? "green" : "red";

    return """
<div class="summary">
    <strong>機器人 SN:</strong>   <span>${report.robotSn}</span>
    <strong>地圖名稱:</strong>     <span>${report.mapName}</span>
    <strong>任務 ID:</strong>      <span>${report.missionId}</span>
    <strong>開始時間:</strong>     <span>${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.taskStartTime)}</span>
    <strong>結束時間:</strong>     <span>${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.taskEndTime)}</span>
    <strong>總耗時:</strong>       <span>$totalDuration</span>
    <strong>最終狀態:</strong>     <span style="color: $statusColor; font-weight: bold;">${report.status}</span>
</div>
""";
  }

  static String _generateLegsTableHtml(List<NavigationLeg> legs) {
    if (legs.isEmpty) {
      return "<p>無導航路徑記錄。</p>";
    }

    final rows = legs.map((leg) {
      final startTime = DateFormat('HH:mm:ss').format(leg.startTime);
      final endTime = DateFormat('HH:mm:ss').format(leg.endTime);
      final duration = _formatDuration(leg.duration);
      final wifiSsid = leg.endWifiSsid ?? 'N/A';
      final wifiRssi = leg.endWifiRssi?.toString() ?? 'N/A';

      return """
<tr>
    <td>${leg.targetLocation}</td>
    <td>$startTime</td>
    <td>$endTime</td>
    <td>$duration</td>
    <td>$wifiSsid</td>
    <td>$wifiRssi</td>
</tr>
""";
    }).join('');

    return """
<table>
    <thead>
        <tr>
            <th>目標地點</th>
            <th>開始時間</th>
            <th>到達時間</th>
            <th>耗時</th>
            <th>WiFi 名稱</th>
            <th>WiFi 強度 (RSSI)</th>
        </tr>
    </thead>
    <tbody>
        $rows
    </tbody>
</table>
""";
  }

  static String _formatDuration(Duration d) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> parts = [];
    if (days > 0) {
      parts.add('$days天');
    }
    if (hours > 0) {
      parts.add('$hours小時');
    }
    if (minutes > 0) {
      parts.add('$minutes分');
    }
    parts.add('$seconds秒');

    return parts.join(' ');
  }
}
