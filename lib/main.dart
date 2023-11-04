import 'dart:async';
import 'dart:convert'; // For json encoding/decoding
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late ConfettiController _confettiController;

  // Variables for counting sit-ups
  int _sitUpCount = 0;
  bool _isUserUp = false;
  bool _isInitialPosition = true;
  Map<String, int> _sitUpLog = {}; // Store date and count

  bool shouldShowCongrats() {
    return _sitUpCount >= 1;
  }

  @override
  void initState() {
    super.initState();
    // ... Other init code
    loadSitUpLog();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          // Use setState to rebuild the UI with new values
          setState(() {
            // Check if the device has been tilted enough to count as a sit-up
            if (event.y > 9.0 && !_isUserUp && !_isInitialPosition) {
              _isUserUp = true;
              _sitUpCount++;
              saveSitUpCount();
              if (_sitUpCount > 0) {
                _confettiController.play();
              }
              // Check if the device can vibrate and provide haptic feedback
              Vibration.hasVibrator().then((bool? hasVibrator) {
                if (hasVibrator ?? false) {
                  Vibration.vibrate(
                      duration: 10); // Vibrate for 100 milliseconds
                }
              });
            } else if (event.y < 1.0 &&
                event.z < 0.0 &&
                (_isUserUp || _isInitialPosition)) {
              // This condition checks if the user has returned to the initial position
              _isUserUp = false;
              _isInitialPosition = false;
            }
          });
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Error"),
                content: Text("Accelerometer events error"),
              );
            },
          );
        },
      ),
    );
  }

  void loadSitUpLog() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sitUpLog = Map<String, int>.from(
          json.decode(prefs.getString('sitUpLog') ?? '{}'));
    });
  }

  void saveSitUpCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = getTodayDate();
    setState(() {
      _sitUpLog[today] = (_sitUpLog[today] ?? 0) + 1; // Increment today's count
      prefs.setString('sitUpLog', json.encode(_sitUpLog)); // Save it
    });
  }

  String getTodayDate() {
    return DateTime.now()
        .toIso8601String()
        .substring(0, 10); // YYYY-MM-DD format
  }

  // Additional Widget to display the log
  Widget sitUpLogWidget() {
    return ListView.builder(
      shrinkWrap: true, // Use only the space needed for children
      itemCount: _sitUpLog.keys.length,
      itemBuilder: (context, index) {
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
        title: Text(widget.title ?? 'Sit-Up Counter'),
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
                const SizedBox(height: 20),
                // Use the shouldShowCongrats function to determine visibility of the "Well done!" text
                Visibility(
                  visible: shouldShowCongrats(),
                  child: const Text(
                    'Well done!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Choose a color that stands out
                    ),
                  ),
                ),
                // Add more space between the "Well done!" text and the counter if needed
                if (shouldShowCongrats()) const SizedBox(height: 20),
                // The rest of your widgets...
                Expanded(
                    child:
                        sitUpLogWidget()), // Make sure it takes the needed space
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // bottom to top
              maxBlastForce: 5, // set a maximum blast force
              minBlastForce: 2, // set a minimum blast force
              numberOfParticles: 50, // number of particles to emit
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
