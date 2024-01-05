import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pushupone/i18n/strings.g.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  LocaleSettings.useDeviceLocale(); // and this
  runApp(TranslationProvider(
      child: const MyApp())); // Wrap your app with TranslationProvider
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sit-Up Counter',
      home: MyHomePage(title: 'Sit-Up Counter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final ScreenshotController screenshotController = ScreenshotController();
  late ConfettiController _confettiController;
  int _sitUpCount = 0;
  bool _isUserUp = false;
  bool _isInitialPosition = true;
  Map<String, int> _sitUpLog = {};

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
    }
    return isFirstLaunch;
  }

  void showIntroductionModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.tutorial_title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(t.tutorial_message1),
                Text(t.tutorial_message2),
                // Example text, add your instructions here
                Image.asset(
                    'assets/instruction_image.png'), // Example image, replace with your asset
                // You can add more text or images
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(t.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int getTotalDays() {
    return _sitUpLog.keys.length;
  }

  int getTotalSitUps() {
    return _sitUpLog.values.fold(0, (sum, element) => sum + element);
  }

  @override
  void initState() {
    super.initState();
    isFirstLaunch().then((isFirst) {
      if (isFirst) {
        // Call function to show modal
        showIntroductionModal();
      }
    });
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    loadSitUpLog();
    _streamSubscriptions.add(accelerometerEvents.listen(
      (AccelerometerEvent event) {
        setState(() {
          if (event.y > 9.0 && !_isUserUp && !_isInitialPosition) {
            _isUserUp = true;
            _sitUpCount++;
            saveSitUpCount();
            if (_sitUpCount > 0) {
              _confettiController.play();
            }
            Vibration.hasVibrator().then((bool? hasVibrator) {
              if (hasVibrator ?? false) {
                Vibration.vibrate(duration: 10);
              }
            });
          } else if (event.y < 1.0 &&
              event.z < 0.0 &&
              (_isUserUp || _isInitialPosition)) {
            _isUserUp = false;
            _isInitialPosition = false;
          }
        });
      },
      onError: (e) {
        if (!mounted) return; // Make sure the context is still valid
        showDialog(
          context:
              context, // Correctly references the BuildContext from the build method
          builder: (BuildContext dialogContext) {
            // Use a different name here to avoid confusion
            return const AlertDialog(
              title: Text("Error"),
              content: Text("Accelerometer events error"),
            );
          },
        );
      },
    ));
  }

  void loadSitUpLog() async {
    final allRows = await DatabaseHelper.instance.queryAllRows();
    final sortedEntries = allRows.map((row) {
      return MapEntry<String, int>(row['date'] as String, row['count'] as int);
    }).toList();

    sortedEntries.sort((a, b) => b.key.compareTo(a.key));

    setState(() {
      _sitUpLog = Map<String, int>.fromEntries(sortedEntries);
    });
  }

  void handleMenuSelection(String choice) async {
    switch (choice) {
      case 'Export to CSV':
        // Call your method to export data
        await exportSitUpLog();
        break;
      case 'Import from CSV':
        // Call your method to import data
        await selectAndImportCsv();
        break;
      case 'Share':
        shareContent();
        break;
      default:
        break;
    }
  }

  void shareContent() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await screenshotController.captureAndSave(directory.path,
        fileName: "screenshot.png");

    // Example message to share
    String message =
        t.share_message.replaceAll('{0}', getTotalSitUps().toString());

    if (imagePath != null) {
      Share.shareXFiles([XFile(imagePath)], text: message);
    }
  }

  String getFormattedDateTime() {
    var now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
  }

  Future<void> exportSitUpLog() async {
    List<List<dynamic>> rows = [
      ['Date', 'Sit-Up Count']
    ];
    // Fetch data from database
    List<Map<String, dynamic>> dbData =
        await DatabaseHelper.instance.queryAllRows();
    for (var row in dbData) {
      List<dynamic> rowList = [row['date'], row['count']];
      rows.add(rowList);
    }

    String csv = const ListToCsvConverter().convert(rows);
    String formattedDateTime = getFormattedDateTime();
    String fileName = "mySitUpData_$formattedDateTime.csv";

    if (Platform.isAndroid) {
      await _saveAndOpenFileAndroid(csv, fileName);
    } else if (Platform.isIOS) {
      await _saveAndShareFileIOS(csv, fileName);
    }
  }

  Future<void> importFromCsv(File file) async {
    final input = await file.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    // Assuming the first row is headers
    rows.removeAt(0);

    // Delete all existing data
    await DatabaseHelper.instance.deleteAllRows();

    for (var row in rows) {
      // Assuming the first column is date and the second is count
      String date = row[0];
      int count = row[1];
      await DatabaseHelper.instance.insert(date, count);
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(t.warning_title),
              content: Text(t.warning_message),
              actions: <Widget>[
                TextButton(
                  child: Text(t.no),
                  onPressed: () =>
                      Navigator.of(context).pop(false), // Returns false
                ),
                TextButton(
                  child: Text(t.yes),
                  onPressed: () =>
                      Navigator.of(context).pop(true), // Returns true
                ),
              ],
            );
          },
        ) ??
        false; // In case the dialog is dismissed, return false by default
  }

  Future<void> selectAndImportCsv() async {
    bool confirm = await showConfirmationDialog(context);
    if (!confirm) {
      return; // User selected "No", so do nothing
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      await importFromCsv(file);

      // Reload the data and update UI
      loadSitUpLog();
    }
  }

  Future<void> _saveAndOpenFileAndroid(String csv, String fileName) async {
    final path = await _localPath;
    final file = File('$path/Download/$fileName');
    await file.writeAsString(csv);
    // TODO: Notify user of success and file location
  }

  Future<void> _saveAndShareFileIOS(String csv, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);
    Share.shareXFiles([XFile(file.path)], text: 'Your sit-up data');
  }

  Future<String?> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory?.path;
  }

  void saveSitUpCount() async {
    final today = getTodayDate();
    final count = (_sitUpLog[today] ?? 0) + 1;
    setState(() {
      _sitUpLog[today] = count;
    });
    await DatabaseHelper.instance.insert(today, count);
    loadSitUpLog();
  }

  String getTodayDate() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  Widget sitUpLogWidget() {
    List<String> sortedKeys = _sitUpLog.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort in descending order of date

    return ListView.separated(
      shrinkWrap: true,
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
      itemBuilder: (BuildContext ctx, int index) {
        String date = sortedKeys[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title:
              Text(date, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text(
            '${_sitUpLog[date]} ${t.situp_count_unit}',
            style: const TextStyle(color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Added ThemeData for consistent styling throughout the app
    return MaterialApp(
      locale: TranslationProvider.of(context).flutterLocale, // use provider
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed:
                () {}, // This needs to be specified, but we'll handle menu opening differently
            child: PopupMenuButton<String>(
              onSelected: handleMenuSelection,
              itemBuilder: (BuildContext context) {
                return {
                  'Share',
                  'Export to CSV',
                  'Import from CSV',
                }.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
            ),
          ),
          body: Screenshot(
            controller: screenshotController,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                    8.0), // Padding around the body content for better spacing
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    final today = getTodayDate();
                    final todaySitUps = _sitUpLog[today] ?? 0;

                    return todaySitUps == 0
                        ? Center(
                            // Content for no sit-ups done today
                            // Content for when no sit-ups have been done today
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    t.start_message,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  "${t.situp_count}: $todaySitUps",
                                  style: const TextStyle(
                                      fontSize: 32, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            // Regular content
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical:
                                        8.0), // Padding around the "Well done!" text
                                child: Text(
                                  t.complete_message,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topCenter,
                                child: ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirection: pi /
                                      2, // pi/2 radians is 90 degrees, pointing downwards
                                  maxBlastForce: 5,
                                  minBlastForce: 2,
                                  numberOfParticles: 50,
                                  gravity: 1,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      20), // Spacing at the top for breathing room
                              Text(
                                "${t.situp_count}: $todaySitUps",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                        color: Colors
                                            .blueAccent), // Larger text with accent color for the count
                              ),
                              Text(
                                "${t.situp_count_days}: ${getTotalDays()}",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight
                                            .w600), // Subtle and less bold for secondary info
                              ),
                              Text(
                                '${t.situp_count_total}: ${getTotalSitUps()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight
                                            .w600), // Consistent styling with the above text
                              ),
                              const SizedBox(
                                  height:
                                      20), // More spacing for a cleaner look
                              Expanded(
                                child:
                                    sitUpLogWidget(), // The list of sit-up counts per day
                              ),
                            ],
                          );
                  },
                ),
              ),
            ),
          )),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _confettiController.dispose();
    super.dispose();
  }
}

class DatabaseHelper {
  static const _databaseName = "SitUpDatabase.db";
  static const _databaseVersion = 1;
  static const table = 'sit_up_table';
  static const columnDate = 'date';
  static const columnCount = 'count';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnDate TEXT PRIMARY KEY,
        $columnCount INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insert(String date, int count) async {
    Database db = await instance.database;
    await db.insert(
      table,
      {columnDate: date, columnCount: count},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAllRows() async {
    Database db = await instance.database;
    await db.delete(table);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table, orderBy: "$columnDate DESC");
  }
}
