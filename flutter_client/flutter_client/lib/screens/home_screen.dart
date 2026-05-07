import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'cabinet_screen.dart';
import 'login_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _documentHash;
  String? _documentName;
  bool _uploading = false;
  UserInfo? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await AuthService.getUser();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _pickAndUpload() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _uploading = false);
        return;
      }

      final req = http.MultipartRequest('POST', Uri.parse('http://localhost:8000/upload-document'));
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        setState(() {
          _documentHash = data['document_hash'] as String;
          _documentName = data['filename'] as String;
          _uploading = false;
        });
      } else {
        setState(() => _uploading = false);
        _showSnack('Upload failed: ${streamed.statusCode}');
      }
    } catch (e) {
      setState(() => _uploading = false);
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Qumyrsqa Tamga', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF00C853)),
            tooltip: 'Cabinet',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CabinetScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_user != null) ...[
                  Text('Welcome, ${_user!.name}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),
                ],
                const _QumyrsqaLogo(),
                const SizedBox(height: 14),
                const Text('TAMGA PROTOCOL', style: TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 4)),
                const SizedBox(height: 6),
                const Text('Qumyrsqa — Tamga Demo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 36),
                const _InfoCard(),
                const SizedBox(height: 28),

                // PDF Upload section
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C853)))
                      : const Text('📄', style: TextStyle(fontSize: 16)),
                  label: Text(_uploading ? 'Uploading...' : 'Upload Document (PDF)'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00C853)),
                    foregroundColor: const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_documentName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2B1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00C853), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📄', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$_documentName — Ready to scan',
                            style: const TextStyle(color: Color(0xFF00C853), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ScanScreen(documentHash: _documentHash)),
                    ),
                    child: const Text('📷  SCAN DOCUMENT'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hardware-anchored data trust layer', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12)),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await AuthService.logout();
                    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  },
                  child: const Text('Sign out', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QumyrsqaLogo extends StatelessWidget {
  const _QumyrsqaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00C853), width: 2),
        color: const Color(0xFF0D2B1A),
      ),
      child: const Center(
        child: Text('Q', style: TextStyle(color: Color(0xFF00C853), fontSize: 56, fontWeight: FontWeight.bold, height: 1)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(18),
      child: const Column(
        children: [
          _InfoRow(icon: '🔐', label: 'Document Hash', desc: 'SHA-256 of uploaded PDF'),
          SizedBox(height: 12),
          _InfoRow(icon: '📡', label: 'GPS Liveness', desc: 'Real-world location anchor'),
          SizedBox(height: 12),
          _InfoRow(icon: '📳', label: 'Gyroscope Proof', desc: 'Physical device check'),
          SizedBox(height: 12),
          _InfoRow(icon: '🔗', label: 'Tol Consensus', desc: '2/3 sources required'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;
  const _InfoRow({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(desc, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
