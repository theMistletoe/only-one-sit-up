import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';

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
  List<double>? _accelerometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late ConfettiController _confettiController;

  // Variables for counting sit-ups
  int _sitUpCount = 0;
  bool _isUserUp = false;
  bool _isInitialPosition = true;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          // Use setState to rebuild the UI with new values
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];

            // Check if the device has been tilted enough to count as a sit-up
            if (event.y > 9.0 && !_isUserUp && !_isInitialPosition) {
              _isUserUp = true;
              _sitUpCount++;
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
                  style: Theme.of(context).textTheme.headline4,
                ),
                const SizedBox(height: 20),
                // Text('Accelerometer: ${_accelerometerValues?.map((double v) => v.toStringAsFixed(1)).join(', ')}'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2, // bottom to top
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
