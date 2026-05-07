import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'sensor_service.dart';

class TolSources {
  final bool document;
  final bool physical;
  final bool neighbor;
  final String consensus;

  const TolSources({
    required this.document,
    required this.physical,
    required this.neighbor,
    required this.consensus,
  });

  factory TolSources.fromJson(Map<String, dynamic> j) => TolSources(
        document: j['document'] as bool,
        physical: j['physical'] as bool,
        neighbor: j['neighbor'] as bool,
        consensus: j['consensus'] as String,
      );
}

class TamgaResult {
  final String tamgaId;
  final double trustScore;
  final bool livenessVerified;
  final bool consensusVerified;
  final String status;
  final String settlement;
  final String message;
  final String solanaExplorer;
  final TolSources tolSources;
  final int latencyMs;
  final String timestamp;
  final Map<String, dynamic> evidence;
  final String hashChain;
  final String sparkplugEvent;
  final Map<String, dynamic> proof;
  final Map<String, dynamic> rawJson;

  const TamgaResult({
    required this.tamgaId,
    required this.trustScore,
    required this.livenessVerified,
    required this.consensusVerified,
    required this.status,
    required this.settlement,
    required this.message,
    required this.solanaExplorer,
    required this.tolSources,
    required this.latencyMs,
    required this.timestamp,
    required this.evidence,
    required this.hashChain,
    required this.sparkplugEvent,
    required this.proof,
    required this.rawJson,
  });

  bool get isVerified => settlement == 'SETTLED';

  factory TamgaResult.fromJson(Map<String, dynamic> json) {
    final rawScore = json['trust_score'];
    final score = rawScore is int ? rawScore.toDouble() : (rawScore as double);
    return TamgaResult(
      tamgaId: json['tamga_id'] as String,
      trustScore: score,
      livenessVerified: json['liveness_verified'] as bool,
      consensusVerified: json['consensus_verified'] as bool,
      status: json['status'] as String,
      settlement: json['settlement'] as String,
      message: json['message'] as String,
      solanaExplorer: json['solana_explorer'] as String,
      tolSources: TolSources.fromJson(json['tol_sources'] as Map<String, dynamic>),
      latencyMs: json['latency_ms'] as int,
      timestamp: json['timestamp'] as String,
      evidence: json['evidence'] as Map<String, dynamic>,
      hashChain: json['hash_chain'] as String,
      sparkplugEvent: json['sparkplug_event'] as String,
      proof: json['qumyrsqa_tamga_proof'] as Map<String, dynamic>,
      rawJson: json,
    );
  }
}

class TamgaService {
  static const String _baseUrl = 'http://localhost:8000';

  static Future<TamgaResult> verifyTamga(SensorData data) async {
    final token = await AuthService.getToken();
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.post(
      Uri.parse('$_baseUrl/verify-tamga'),
      headers: headers,
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode == 200) {
      return TamgaResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Server error ${response.statusCode}: ${response.body}');
  }

  static Future<Map<String, dynamic>> getTamgaById(String tamgaId) async {
    final resp = await http.get(Uri.parse('$_baseUrl/verify-tamga/$tamgaId'));
    if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
    throw Exception('Not found: $tamgaId');
  }
}
