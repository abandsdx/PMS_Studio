import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models/report_model.dart';
import 'navigation_controller.dart';
import 'report_generator.dart';
import 'widgets/log_console.dart';

// Enum for the new navigation order feature
enum NavigationOrder { sorted, random }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Navigation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NavigationPage(),
    );
  }
}

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  NavigationPageState createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
  static const String _initialApiKey = "Basic YOUR_AUTH_TOKEN_HERE";
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxLogLines = 1000;
  static const int _logLinesToRemove = 100;

  late ApiService apiService;
  late NavigationController controller;

  // State for maps
  String? selectedMapName;
  List<String> mapNames = [];

  // State for robots
  String? selectedSn;
  List<String> robotSns = [];

  // State for navigation order
  NavigationOrder _selectedOrder = NavigationOrder.sorted;

  // State for logging and reports
  List<String> logLines = [];
  TaskReport? lastTaskReport;
  bool isRunning = false;
  bool _isStopping = false;

  final TextEditingController apiKeyController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    apiKeyController.text = _initialApiKey;
    _updateApiKey();
  }

  void _updateApiKey() {
    final newApiKey = apiKeyController.text.trim();
    if (newApiKey.isEmpty) {
      addLog("API 金鑰不可為空!");
      return;
    }

    setState(() {
      apiService = ApiService(authHeader: newApiKey);
      controller = NavigationController(apiService, addLog);
    });

    addLog("API 金鑰已更新，正在重新抓取資料...");
    loadMapNames();
    loadRobots();
  }

  Future<void> loadMapNames({int retryCount = 0}) async {
    try {
      final maps = await apiService.getLocations();
      if (!mounted) return;
      setState(() {
        selectedMapName = null;
        mapNames = maps
            .where((map) => map.mapName != null)
            .map((map) => map.mapName!)
            .toSet()
            .toList();
      });
      if (mapNames.isNotEmpty) {
        addLog("地圖列表已成功載入!");
      } else {
        addLog("未找到可用的地圖。");
      }
    } on MapIsProcessingException {
      if (retryCount < _maxRetries) {
        addLog("地圖資料生成中，${_retryDelay.inSeconds}秒後重試... (第 ${retryCount + 1} 次)");
        await Future.delayed(_retryDelay);
        loadMapNames(retryCount: retryCount + 1);
      } else {
        addLog("地圖資料生成超時，請稍後再試。");
      }
    } catch (e) {
      addLog("抓取 MapNames 失敗: $e");
    }
  }

  Future<void> loadRobots() async {
    try {
      addLog("正在獲取機器人列表...");
      final robots = await apiService.getRobots();
      if (!mounted) return;
      setState(() {
        selectedSn = null;
        robotSns = robots.map((robot) => robot.sn).toSet().toList();
      });
      if (robotSns.isNotEmpty) {
        addLog("機器人列表已成功載入!");
      } else {
        addLog("未找到可用的機器人。");
      }
    } catch (e) {
      addLog("抓取機器人列表失敗: $e");
    }
  }

  void addLog(String text) {
    if (!mounted) return;
    setState(() {
      if (logLines.length > _maxLogLines) {
        logLines.removeRange(0, _logLinesToRemove);
      }
      logLines.add(text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> startNavigation() async {
    if (selectedSn == null) {
      addLog("請先選擇機器人 SN!");
      return;
    }
    if (selectedMapName == null) {
      addLog("請先選擇 MapName!");
      return;
    }

    if (!mounted) return;
    setState(() {
      isRunning = true;
      _isStopping = false; // Reset stop flag at the beginning
      lastTaskReport = null;
    });

    final report = await controller.startNavigation(
      selectedSn!,
      selectedMapName!,
      navigationOrder: _selectedOrder,
      isStopping: () => _isStopping,
    );

    if (!mounted) return;
    setState(() {
      isRunning = false;
      lastTaskReport = report;
    });
  }

  void _stopNavigation() {
    addLog("正在發送停止命令...");
    setState(() {
      _isStopping = true;
    });
  }

  Future<void> _generateAndSaveReport() async {
    if (lastTaskReport == null) {
      addLog("沒有可用的報告。請先完成一次導航任務。");
      return;
    }

    addLog("正在準備產生報告...");
    try {
      String? outputDirectory = await FilePicker.platform.getDirectoryPath();

      if (outputDirectory == null) {
        addLog("使用者取消儲存操作。");
        return;
      }

      final reportHtml = ReportGenerator.generateHtmlReport(lastTaskReport!);
      final filename = ReportGenerator.generateFilename(lastTaskReport!);
      final filePath = '$outputDirectory${Platform.pathSeparator}$filename';

      final file = File(filePath);
      await file.writeAsString(reportHtml);

      addLog("報告已成功儲存至: $filePath");
    } catch (e) {
      addLog("產生或儲存報告時發生錯誤: $e");
    }
  }

  void _clearLogs() {
    setState(() {
      logLines.clear();
      addLog("日誌已手動清除。");
    });
  }

  @override
  Widget build(BuildContext context) {
    final canGenerateReport = !isRunning && lastTaskReport != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Robot Navigation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // API Key Input
            Row(
              children: [
                const Text("輸入 API 金鑰: "),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "請輸入 API 金鑰",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _updateApiKey,
                  child: const Text("套用"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Robot Selection
            Row(
              children: [
                const Text("選擇機器人 SN: "),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedSn,
                  hint: const Text("請選擇"),
                  items: robotSns.map((sn) {
                    return DropdownMenuItem(value: sn, child: Text(sn));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedSn = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Map Selection
            Row(
              children: [
                const Text("選擇 MapName: "),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedMapName,
                  hint: const Text("請選擇"),
                  items: mapNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedMapName = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Navigation Order Selection
            _NavigationOrderSelector(
              selectedOrder: _selectedOrder,
              onOrderChanged: (value) {
                if (value != null) {
                  setState(() => _selectedOrder = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRunning)
                  ElevatedButton(
                    onPressed: _stopNavigation,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("停止"),
                  )
                else
                  ElevatedButton(
                    onPressed: startNavigation,
                    child: const Text("開始循環導航"),
                  ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: canGenerateReport ? _generateAndSaveReport : null,
                  child: const Text("產生報告"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text("清除日誌"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Log Console
            Expanded(
              child: LogConsole(
                logLines: logLines,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A private widget to encapsulate the radio button logic.
class _NavigationOrderSelector extends StatelessWidget {
  const _NavigationOrderSelector({
    required this.selectedOrder,
    required this.onOrderChanged,
  });

  final NavigationOrder selectedOrder;
  final ValueChanged<NavigationOrder?> onOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("導航順序: "),
        Expanded(
          child: RadioListTile<NavigationOrder>(
            title: const Text('排序'),
            value: NavigationOrder.sorted,
            // ignore: deprecated_member_use
            groupValue: selectedOrder,
            // ignore: deprecated_member_use
            onChanged: onOrderChanged,
          ),
        ),
        Expanded(
          child: RadioListTile<NavigationOrder>(
            title: const Text('隨機'),
            value: NavigationOrder.random,
            // ignore: deprecated_member_use
            groupValue: selectedOrder,
            // ignore: deprecated_member_use
            onChanged: onOrderChanged,
          ),
        ),
      ],
    );
  }
}
