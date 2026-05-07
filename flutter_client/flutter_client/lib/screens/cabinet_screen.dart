import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AuthService.getCabinet();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Personal Cabinet', style: TextStyle(color: Color(0xFF00C853))),
        iconTheme: const IconThemeData(color: Color(0xFF00C853)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final user = _data!['user'] as Map<String, dynamic>;
    final stats = _data!['stats'] as Map<String, dynamic>;
    final history = _data!['history'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF00C853),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _UserCard(name: user['name'] as String, email: user['email'] as String),
          const SizedBox(height: 20),
          _StatsRow(
            total: stats['total_scans'] as int,
            verified: stats['verified'] as int,
            blocked: stats['blocked'] as int,
          ),
          const SizedBox(height: 24),
          const Text(
            'VERIFICATION HISTORY',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const _EmptyHistory()
          else
            ...history.map((h) => _HistoryItem(item: h as Map<String, dynamic>)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  const _UserCard({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C853), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D2B1A)),
            child: const Center(child: Text('Q', style: TextStyle(color: Color(0xFF00C853), fontSize: 28, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(email, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int verified;
  final int blocked;
  const _StatsRow({required this.total, required this.verified, required this.blocked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total', value: '$total', color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Verified', value: '$verified', color: const Color(0xFF00C853))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Blocked', value: '$blocked', color: Colors.redAccent)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String? ?? 'UNKNOWN';
    final score = item['trust_score'];
    final ts = item['timestamp'] as String? ?? '';
    final isVerified = status == 'VERIFIED';
    final scoreStr = score != null ? '${((score as num).toDouble() * 100).toStringAsFixed(0)}%' : '—';
    final dateStr = ts.length >= 19 ? ts.substring(0, 19).replaceAll('T', ' ') : ts;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isVerified ? const Color(0xFF00C853) : Colors.redAccent, width: 0.5),
      ),
      child: Row(
        children: [
          Text(isVerified ? '✅' : '🚫', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['tamga_id'] as String? ?? '').length > 18
                      ? '${(item['tamga_id'] as String).substring(0, 18)}...'
                      : (item['tamga_id'] as String? ?? ''),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                ),
                Text(dateStr, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(color: isVerified ? const Color(0xFF00C853) : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(scoreStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text('No scans yet.\nPress SCAN DOCUMENT to get started.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13), textAlign: TextAlign.center),
      ),
    );
  }
}
