import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  runApp(const MyApp());
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
          title: const Text("このアプリの使い方"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text("1日一回だけ、胸にスマホを置いて腹筋しましょう!"),
                // Example text, add your instructions here
                Image.asset(
                    'assets/instruction_image.png'), // Example image, replace with your asset
                // You can add more text or images
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
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
        print("First launch");
        print(isFirst);
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
      // Explicitly cast the types of the map entries
      return MapEntry<String, int>(row['date'] as String, row['count'] as int);
    }).toList();

    // Sort the entries in descending order of date
    sortedEntries.sort((a, b) => b.key.compareTo(a.key));

    setState(() {
      _sitUpLog = Map<String, int>.fromEntries(sortedEntries);
    });
  }

  void saveSitUpCount() async {
    final today = getTodayDate();
    final count = (_sitUpLog[today] ?? 0) + 1;
    setState(() {
      _sitUpLog[today] = count;
    });
    await DatabaseHelper.instance.insert(today, count);
  }

  String getTodayDate() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  Widget sitUpLogWidget() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _sitUpLog.keys.length,
      separatorBuilder: (context, index) => Divider(
          color: Colors.grey[
              300]), // Adds a divider between list items for better readability
      itemBuilder: (BuildContext ctx, int index) {
        String date = _sitUpLog.keys.elementAt(index);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0), // Padding inside each list tile
          title: Text(date,
              style: const TextStyle(
                  fontWeight: FontWeight.w500)), // Bolder text for the date
          trailing: Text(
            '${_sitUpLog[date]} sit-ups',
            style: const TextStyle(
                color: Colors.blueAccent), // Accent color for the sit-up count
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Added ThemeData for consistent styling throughout the app
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          // Gives a bit of shadow to the AppBar for a subtle depth effect
          elevation: 4.0,
          centerTitle: true, // Centers the title on the AppBar
          backgroundColor:
              Colors.blueAccent, // A more vibrant color for the AppBar
        ),
        body: Padding(
          padding: const EdgeInsets.all(
              8.0), // Padding around the body content for better spacing
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection:
                      pi / 2, // pi/2 radians is 90 degrees, pointing downwards
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  numberOfParticles: 50,
                  gravity: 1,
                ),
              ),
              const SizedBox(
                  height: 20), // Spacing at the top for breathing room
              Text(
                'Sit-ups: $_sitUpCount',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors
                        .blueAccent), // Larger text with accent color for the count
              ),
              Text(
                'Total Days: ${getTotalDays()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight
                        .w600), // Subtle and less bold for secondary info
              ),
              Text(
                'Total Sit-Ups: ${getTotalSitUps()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight
                        .w600), // Consistent styling with the above text
              ),
              const SizedBox(height: 20), // More spacing for a cleaner look
              if (_sitUpCount > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 8.0), // Padding around the "Well done!" text
                  child: Text(
                    'Well done!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              Expanded(
                child: sitUpLogWidget(), // The list of sit-up counts per day
              ),
            ],
          ),
        ),
      ),
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

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table, orderBy: "$columnDate DESC");
  }
}
