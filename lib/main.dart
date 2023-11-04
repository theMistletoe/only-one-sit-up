import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  // Variables for counting sit-ups
  int _sitUpCount = 0;
  bool _isUserUp = false;
  final double _sitUpThreshold = 9.81 / 2; // Adjust the threshold accordingly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Sit-Up Counter'),
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Sit-ups: $_sitUpCount',
              style: Theme.of(context).textTheme.headline4,
            ),
            const SizedBox(height: 20),
            Text(
                'Accelerometer: ${_accelerometerValues?.map((v) => v.toStringAsFixed(1)).join(', ')}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          // Use setState to rebuild the UI with new values
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];

            // Check if the device has been tilted enough to count as a sit-up
            if (event.y > 9.0 && !_isUserUp) {
              _isUserUp = true;
              _sitUpCount++;
            } else if (event.y < 1.0 && _isUserUp) {
              // This condition checks if the user has returned to the initial position
              _isUserUp = false;
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
}
