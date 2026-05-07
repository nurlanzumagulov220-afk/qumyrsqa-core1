import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tamga_service.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final TamgaResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tamga Result',
          style: TextStyle(color: Color(0xFF00C853)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBanner(result: result),
            const SizedBox(height: 16),
            _TamgaIdBadge(tamgaId: result.tamgaId),
            const SizedBox(height: 16),
            _TrustScoreCard(result: result),
            const SizedBox(height: 16),
            _TolSourcesCard(sources: result.tolSources),
            const SizedBox(height: 16),
            _EvidenceCard(result: result),
            const SizedBox(height: 16),
            _SolanaCard(result: result),
            const SizedBox(height: 16),
            _RawJsonCard(json: result.rawJson),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openUrl(result.solanaExplorer),
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('VIEW ON SOLANA DEVNET'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _openUrl('http://localhost:8000/docs'),
              icon: const Icon(Icons.api, size: 18),
              label: const Text('VIEW IN SWAGGER'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (r) => false,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C853)),
                foregroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('SCAN AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Big Status Banner ────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final TamgaResult result;
  const _StatusBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final isVerified = result.isVerified;
    final bg = isVerified ? const Color(0xFF0D2B1A) : const Color(0xFF2B0D0D);
    final border = isVerified ? const Color(0xFF00C853) : Colors.redAccent;
    final icon = isVerified ? '✅' : '🚫';
    final label = isVerified
        ? 'VERIFIED — Funds Released'
        : 'BLOCKED — Funds Frozen';
    final sub = isVerified
        ? 'Tol Consensus: ${result.tolSources.consensus} sources confirmed'
        : 'Insufficient consensus — transaction blocked';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: border,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: TextStyle(
              color: border,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tamga ID Badge ───────────────────────────────────────────────────────────

class _TamgaIdBadge extends StatelessWidget {
  final String tamgaId;
  const _TamgaIdBadge({required this.tamgaId});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Text(
            'TAMGA ID',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tamgaId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tamga ID скопирован')),
              );
            },
            child: Text(
              tamgaId,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'tap to copy',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Trust Score ──────────────────────────────────────────────────────────────

class _TrustScoreCard extends StatelessWidget {
  final TamgaResult result;
  const _TrustScoreCard({required this.result});

  Color get _color =>
      result.trustScore >= 0.80 ? const Color(0xFF00C853) : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final pct = (result.trustScore * 100).toStringAsFixed(0);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trust Score',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('$pct%',
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 24)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.trustScore,
              backgroundColor: const Color(0xFF1F2937),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Pill(
                  label: 'Consensus',
                  value: result.tolSources.consensus,
                  color: const Color(0xFF00C853)),
              _Pill(
                  label: 'Latency',
                  value: '${result.latencyMs}ms',
                  color: Colors.amberAccent),
              _Pill(
                  label: 'Liveness',
                  value: result.livenessVerified ? '✅' : '❌',
                  color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Pill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Tol Sources ──────────────────────────────────────────────────────────────

class _TolSourcesCard extends StatelessWidget {
  final TolSources sources;
  const _TolSourcesCard({required this.sources});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOL CONSENSUS SOURCES',
            style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _SourceRow(
              icon: '📄',
              label: 'Document Hash',
              verified: sources.document),
          const SizedBox(height: 10),
          _SourceRow(
              icon: '📳',
              label: 'Physical Device (Gyro + GPS)',
              verified: sources.physical),
          const SizedBox(height: 10),
          _SourceRow(
              icon: '🛰',
              label: 'Virtual Neighbor',
              verified: sources.neighbor),
          const Divider(color: Color(0xFF1F2937), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Consensus',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(
                sources.consensus,
                style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool verified;
  const _SourceRow(
      {required this.icon, required this.label, required this.verified});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Text(
          verified ? '✅' : '❌',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

// ── Evidence ─────────────────────────────────────────────────────────────────

class _EvidenceCard extends StatelessWidget {
  final TamgaResult result;
  const _EvidenceCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final e = result.evidence;
    final shortHash = result.hashChain.length > 24
        ? '${result.hashChain.substring(0, 24)}...'
        : result.hashChain;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVIDENCE',
            style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Device ID', value: e['device_id'] ?? '—'),
          const _Divider(),
          _InfoRow(label: 'Location', value: e['geo'] ?? '—'),
          const _Divider(),
          _InfoRow(label: 'File', value: e['file'] ?? '—',
              valueColor: Colors.amberAccent),
          const _Divider(),
          _InfoRow(
              label: 'Hash Chain',
              value: shortHash,
              monospace: true,
              valueColor: Colors.white54),
          const _Divider(),
          _InfoRow(label: 'Sparkplug', value: result.sparkplugEvent,
              valueColor: Colors.amberAccent),
        ],
      ),
    );
  }
}

// ── Solana Card ──────────────────────────────────────────────────────────────

class _SolanaCard extends StatelessWidget {
  final TamgaResult result;
  const _SolanaCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final shortTx = result.solanaExplorer.contains('/tx/')
        ? result.solanaExplorer.split('/tx/').last.split('?').first
        : '—';
    final displayTx = shortTx.length > 20
        ? '${shortTx.substring(0, 20)}...'
        : shortTx;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('◎', style: TextStyle(color: Color(0xFF9945FF), fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'SOLANA DEVNET',
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'TX',
            value: displayTx,
            monospace: true,
            valueColor: const Color(0xFF9945FF),
          ),
          const _Divider(),
          const _InfoRow(
            label: 'Network',
            value: 'devnet',
            valueColor: Colors.amberAccent,
          ),
          const _Divider(),
          _InfoRow(
            label: 'Timestamp',
            value: result.timestamp.length > 19
                ? result.timestamp.substring(0, 19).replaceAll('T', ' ')
                : result.timestamp,
            valueColor: Colors.white54,
          ),
        ],
      ),
    );
  }
}

// ── Raw JSON ─────────────────────────────────────────────────────────────────

class _RawJsonCard extends StatefulWidget {
  final Map<String, dynamic> json;
  const _RawJsonCard({required this.json});

  @override
  State<_RawJsonCard> createState() => _RawJsonCardState();
}

class _RawJsonCardState extends State<_RawJsonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final prettyJson =
        const JsonEncoder.withIndent('  ').convert(widget.json);

    return _Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.code, color: Color(0xFF00C853), size: 18),
                  const SizedBox(width: 8),
                  const Text('Raw JSON Response',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                prettyJson,
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool monospace;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white70,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: monospace ? 'monospace' : null,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFF1F2937), height: 20);
  }
}
