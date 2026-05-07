import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../services/tamga_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  final String? documentHash;
  const ScanScreen({super.key, this.documentHash});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _status = 'Инициализация датчиков...';
  int _step = 0;

  static const _steps = [
    'Определение устройства...',
    'Получение GPS-координат...',
    'Чтение гироскопа...',
    'Сканирование Wi-Fi...',
    'Подготовка хэша документа...',
    'Отправка в Tamga-сервер...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _runScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    for (int i = 0; i < _steps.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() { _step = i + 1; _status = _steps[i]; });
    }

    try {
      final sensorData = await SensorService.collectAll(
        documentHashOverride: widget.documentHash,
      );

      if (!mounted) return;
      setState(() { _status = _steps[_steps.length - 1]; _step = _steps.length; });

      final result = await TamgaService.verifyTamga(sensorData);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Ошибка', style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); },
            child: const Text('Назад', style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tamga Scan', style: TextStyle(color: Color(0xFF00C853))),
        iconTheme: const IconThemeData(color: Color(0xFF00C853)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.documentHash != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0D2B1A), borderRadius: BorderRadius.circular(8)),
                  child: const Text('📄 PDF document linked', style: TextStyle(color: Color(0xFF00C853), fontSize: 11)),
                ),
                const SizedBox(height: 24),
              ],
              _ScannerAnimation(controller: _controller),
              const SizedBox(height: 40),
              Text(_status, style: const TextStyle(color: Color(0xFF00C853), fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _StepIndicator(currentStep: _step, total: _steps.length),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _step / _steps.length,
                  backgroundColor: const Color(0xFF1F2937),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerAnimation extends StatelessWidget {
  final AnimationController controller;
  const _ScannerAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final glow = (0.15 + 0.25 * controller.value).clamp(0.0, 1.0);
        return Container(
          width: 180, height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color.lerp(const Color(0xFF00C853), const Color(0xFF004D20), controller.value)!, width: 3),
            color: Color.fromRGBO(13, 43, 26, glow),
          ),
          child: const Center(child: Text('Q', style: TextStyle(color: Color(0xFF00C853), fontSize: 80, fontWeight: FontWeight.bold))),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int total;
  const _StepIndicator({required this.currentStep, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final done = i < currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: done ? 12 : 8,
          height: done ? 12 : 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? const Color(0xFF00C853) : const Color(0xFF1F2937)),
        );
      }),
    );
  }
}
