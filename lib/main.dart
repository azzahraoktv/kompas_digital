import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor & GNSS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SensorGnssScreen(),
    );
  }
}

class SensorGnssScreen extends StatefulWidget {
  const SensorGnssScreen({super.key});

  @override
  State<SensorGnssScreen> createState() => _SensorGnssScreenState();
}

class _SensorGnssScreenState extends State<SensorGnssScreen> {
  // 1. Data GNSS/GPS
  Position? _currentPosition;
  String _locationStatus = 'Inisialisasi...';

  // 2 & 3. Data IMU & Magnetometer
  List<double> _accelerometerValues = [0, 0, 0];
  List<double> _gyroscopeValues = [0, 0, 0];
  List<double> _magnetometerValues = [0, 0, 0];
  
  // Streams untuk mengontrol data real-time
  late StreamSubscription<Position> _positionStreamSubscription;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartLocation();
    _startSensorStreams();
  }

  @override
  void dispose() {
    // Matikan semua sensor saat layar ditutup
    _positionStreamSubscription.cancel();
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _magnetometerSubscription.cancel();
    super.dispose();
  }

  // --- FUNGSI GNSS/GPS (Point 1) ---
  Future<void> _checkPermissionAndStartLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = 'Layanan Lokasi dinonaktifkan.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = 'Izin Lokasi ditolak.');
        return;
      }
    }
    
    // Mulai streaming lokasi
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // Update setiap 1 meter
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Aktif';
        });
      },
      onError: (e) {
        setState(() => _locationStatus = 'Error Lokasi: $e');
      },
    );
  }

  // --- FUNGSI IMU & MAGNETOMETER (Point 2 & 3) ---
  void _startSensorStreams() {
    // 2. Accelerometer (IMU)
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.ui.duration).listen(
      (AccelerometerEvent event) {
        setState(() => _accelerometerValues = [event.x, event.y, event.z]);
      },
    );

    // 2. Gyroscope (IMU)
    _gyroscopeSubscription = gyroscopeEventStream(samplingPeriod: SensorInterval.ui.duration).listen(
      (GyroscopeEvent event) {
        setState(() => _gyroscopeValues = [event.x, event.y, event.z]);
      },
    );

    // 3. Magnetometer (Kompas Sederhana)
    _magnetometerSubscription = magnetometerEventStream(samplingPeriod: SensorInterval.ui.duration).listen(
      (MagnetometerEvent event) {
        setState(() => _magnetometerValues = [event.x, event.y, event.z]);
      },
    );
  }

  // Widget tampilan data
  Widget _buildDataCard({required String title, required List<String> data}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            ...data.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(item, style: const TextStyle(fontSize: 16)),
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format data GPS
    final gpsData = _currentPosition != null ? [
      'Lintang (Lat): ${_currentPosition!.latitude.toStringAsFixed(6)}',
      'Bujur (Lon): ${_currentPosition!.longitude.toStringAsFixed(6)}',
      'Ketinggian (Alt): ${_currentPosition!.altitude.toStringAsFixed(2)} m',
      'Kecepatan (Speed): ${_currentPosition!.speed.toStringAsFixed(2)} m/s',
      'Status: $_locationStatus',
    ] : [ 'Data Lokasi Belum Tersedia', 'Status: $_locationStatus', ];

    // Format data Sensor IMU dan Magnetometer
    final imuData = ['X: ${_accelerometerValues[0].toStringAsFixed(4)} G', 'Y: ${_accelerometerValues[1].toStringAsFixed(4)} G', 'Z: ${_accelerometerValues[2].toStringAsFixed(4)} G',];
    final gyroData = ['X: ${_gyroscopeValues[0].toStringAsFixed(4)} rad/s', 'Y: ${_gyroscopeValues[1].toStringAsFixed(4)} rad/s', 'Z: ${_gyroscopeValues[2].toStringAsFixed(4)} rad/s',];
    final magData = ['X: ${_magnetometerValues[0].toStringAsFixed(4)} \u{00B5}T', 'Y: ${_magnetometerValues[1].toStringAsFixed(4)} \u{00B5}T', 'Z: ${_magnetometerValues[2].toStringAsFixed(4)} \u{00B5}T',];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GNSS, IMU, & Kompas'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildDataCard(title: '🛰️ GNSS/GPS Data', data: gpsData),
            _buildDataCard(title: '🚀 Accelerometer (Akselerasi)', data: imuData),
            _buildDataCard(title: '🔄 Gyroscope (Kecepatan Sudut)', data: gyroData),
            _buildDataCard(title: '🧭 Magnetometer (Kompas Mentah)', data: magData),
          ],
        ),
      ),
    );
  }
}