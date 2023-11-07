import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
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

  int getTotalDays() {
    return _sitUpLog.keys.length;
  }

  int getTotalSitUps() {
    return _sitUpLog.values.fold(0, (sum, element) => sum + element);
  }

  @override
  void initState() {
    super.initState();
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
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _sitUpLog.keys.length,
      itemBuilder: (BuildContext ctx, int index) {
        // Renamed context to ctx to avoid shadowing
        String date = _sitUpLog.keys.elementAt(index);
        return ListTile(
          title: Text(date),
          trailing: Text('${_sitUpLog[date]} sit-ups'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 4,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Sit-ups: $_sitUpCount',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Total Days: ${getTotalDays()}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Total Sit-Ups: ${getTotalSitUps()}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                if (_sitUpCount >= 1)
                  const Text(
                    'Well done!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                if (_sitUpCount >= 1) const SizedBox(height: 20),
                Expanded(child: sitUpLogWidget()),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              numberOfParticles: 50,
              gravity: 1,
            ),
          ),
        ],
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
