QumyrsqaCore

Execution Oracle for Solana
Converts real-world events into autonomous on-chain settlements.

---

🚨 Problem

Smart contracts cannot verify real-world events.

Businesses today:

- lose money on fraud
- rely on manual verification
- spend days on arbitration

Result: slow, expensive, unreliable trust.

---

⚡ Solution

QumyrsqaCore is an execution oracle that:

1. Captures a real-world event (QR / sensor / upload)
2. Verifies it via deterministic consensus (Tamga → Tol)
3. Calculates Trust Score from multiple independent sources (quorum-based validation)
4. Automatically executes a smart contract on Solana

👉 If Trust > threshold → funds are released
👉 If Trust ≤ threshold → funds are blocked

---

🔄 Demo Flow

Document Upload / QR Scan
        ↓
Tamga (event identity + signature)
        ↓
Tol (verification consensus)
        ↓
Trust Score (e.g. 87%)
        ↓
Solana Transaction (Devnet)
        ↓
Escrow → SETTLED or BLOCKED

---

🎯 Use Case — LegalTech (Nace.AI)

Verified Audit → Automatic Settlement

Before:

- manual audit verification
- fraud risk
- long dispute resolution

After:

- instant verification (<3 sec)
- automatic escrow release
- zero fraudulent payouts

---

🏗 Architecture

- Go (Aksakal Gateway) — event processing & oracle signing
- Rust (Anchor) — Solana smart contract
- React — Event Visualizer
- SQLite (Edge) — local event storage
- Solana Devnet — execution layer

---

🔐 Security

- Ed25519 oracle signature verification (on-chain)
- Replay protection (event processed flag + PDA)
- Escrow accounts via PDA
- Oracle private key isolated on edge device

---

🔗 Example Transaction (Devnet)

https://explorer.solana.com/tx/✅ Solana TX confirmed
5bdl9voegyh8
⏱ Latency to settlement: 2.313s

---

💻 How to Run (Demo)

1. Start Gateway

go run cmd/field_hub/main.go

2. Deploy Solana Program

anchor build
anchor deploy --provider.cluster devnet

3. Run Visualizer

cd web/visualizer
npm install
npm run dev

---

📦 SDK Example

import { Qumyrsqa } from '@tsp/core-sdk';

const qr = new Qumyrsqa({
  clientId: 'demo',
  apiKey: 'qmc_live_xxx'
});

const event = await qr.verify({
  document_hash: 'sha256:abc123',
  document_type: 'legal_audit',
  counterparty_id: 'KZ-ENT-001'
});

console.log(event.status);     // FINAL / BLOCKED
console.log(event.trustScore); // 87

---

🧪 Demo Scenarios

✅ Valid Event

- Trust Score: 87%
- Status: SETTLED
- Funds released

❌ Invalid Event

- Trust Score: 45%
- Status: BLOCKED
- Funds frozen

---

⚡ Why Solana

- Sub-second finality
- Ultra-low transaction fees
- Ideal for high-frequency real-world events

---

🧠 Innovation

We solve the oracle problem:

«Turning real-world events into trusted, executable blockchain actions»

Not just data →
👉 Execution layer for reality

---
## 🏆 Hackathon Status
- **Solana Frontier Hackathon** (Apr 6 – May 10)
- Project on Colosseum: [QumyrsqaCore](https://arena.colosseum.org/...)
- Weekly Update video: [Loom / YouTube](твоя_ссылка_на_видео)
🚀 Status

- MVP (Devnet)
- Working oracle → smart contract bridge
- Real use case: LegalTech (audit verification)

---

📬 Contact

Team TSP
QumyrsqaCore

---
