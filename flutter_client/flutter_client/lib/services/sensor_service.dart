import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorData {
  final String deviceId;
  final Map<String, dynamic> gps;
  final Map<String, dynamic> gyroscope;
  final List<String> wifiMac;
  final String timestamp;
  final String documentHash;

  SensorData({
    required this.deviceId,
    required this.gps,
    required this.gyroscope,
    required this.wifiMac,
    required this.timestamp,
    required this.documentHash,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'gps': gps,
        'gyroscope': gyroscope,
        'wifi_mac': wifiMac,
        'timestamp': timestamp,
        'document_hash': documentHash,
      };
}

class SensorService {
  static Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        final raw =
            '${webInfo.browserName.name}-${webInfo.platform}-${webInfo.userAgent}';
        return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
      }
    } catch (_) {}
    return 'DEMO-DEVICE-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<Map<String, dynamic>> _getGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _deniedGps();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _deniedGps();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _deniedGps();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (_) {
      return _deniedGps();
    }
  }

  static Map<String, dynamic> _deniedGps() {
    // Zero coordinates signal to backend that GPS is unavailable/denied.
    // Backend will set geo_valid = false → physical_verified = false.
    return {'lat': 0.0, 'lng': 0.0, 'accuracy': 0.0};
  }

  static Future<Map<String, dynamic>> _getGyroscope() async {
    try {
      final completer = Completer<Map<String, dynamic>>();
      StreamSubscription? sub;

      sub = gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval)
          .listen((event) {
        sub?.cancel();
        completer.complete({
          'x': double.parse(event.x.toStringAsFixed(4)),
          'y': double.parse(event.y.toStringAsFixed(4)),
          'z': double.parse(event.z.toStringAsFixed(4)),
        });
      }, onError: (_) {
        sub?.cancel();
        completer.complete(_mockGyroscope());
      });

      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub?.cancel();
          return _mockGyroscope();
        },
      );
    } catch (_) {
      return _mockGyroscope();
    }
  }

  static Map<String, dynamic> _mockGyroscope() {
    return {'x': 0.0312, 'y': -0.0187, 'z': 0.0043};
  }

  static String _generateDocumentHash() {
    final now = DateTime.now().toIso8601String();
    final bytes = utf8.encode('QUMYRSQA_SCAN_$now');
    return sha256.convert(bytes).toString();
  }

  static Future<SensorData> collectAll({String? documentHashOverride}) async {
    final results = await Future.wait([
      _getDeviceId(),
      _getGPS(),
      _getGyroscope(),
    ]);

    final deviceId = results[0] as String;
    final gps = results[1] as Map<String, dynamic>;
    final gyroscope = results[2] as Map<String, dynamic>;

    return SensorData(
      deviceId: deviceId,
      gps: gps,
      gyroscope: gyroscope,
      wifiMac: const ['AA:BB:CC:DD:EE:FF'],
      timestamp: DateTime.now().toIso8601String(),
      documentHash: documentHashOverride ?? _generateDocumentHash(),
    );
  }
}
