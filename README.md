# QumyrsqaCore

[![Demo Video](https://img.youtube.com/vi/z3qcDvhTxAU/0.jpg)](https://youtu.be/z3qcDvhTxAU)

**Execution Oracle for Solana** — converts real-world events into autonomous on-chain settlements.

QR / Upload → Tamga → Tol → Trust Score → Solana TX → Funds Released

---

## 🚨 Problem

Smart contracts cannot verify real-world events.

Businesses lose money on fraud, rely on manual verification, and spend days on arbitration.

---

## ⚡ Solution

QumyrsqaCore is an execution oracle that:

1. Captures a real-world event (QR / sensor / upload)
2. Verifies it via deterministic consensus (Tamga → Tol)
3. Calculates Trust Score from multiple independent sources (quorum-based validation)
4. Automatically executes a Solana smart contract — funds released if trusted, blocked if not

---

## 🔄 Demo Flow

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

## 🎯 Use Case — LegalTech (Nice.like)

**Verified Audit → Automatic Settlement**

Before: manual audit verification, fraud risk, long dispute resolution
After: instant verification (<3 sec), automatic escrow release, zero fraudulent payouts

---

## 🏗 Architecture

- Go (Aksakal Gateway) — event processing & oracle signing
- Rust (Anchor) — Solana smart contract
- React — Event Visualizer (Web Dashboard)
- SQLite (Edge) — local event storage
- Solana Devnet — execution layer

---

## 🧑‍💻 Tech Stack & Team

| Layer          | Tech                        | Contributor |
|----------------|-----------------------------|-------------|
| Blockchain     | Rust (Anchor) on Solana     | @nurlanzumagulov220-afk (Kalb Master) |
| Edge Node      | Go (Aksakal Gateway)        | @nurlanzumagulov220-afk (Kalb Master) |
| API Gateway    | **Python (FastAPI)**        | **@momortis08-dev (Kaisar)** |
| Frontend (Web) | React + TypeScript + Vite   | @nurlanzumagulov220-afk (Kalb Master) |
| Frontend (Mobile) | **Flutter (Dart)**       | **@momortis08-dev (Kaisar)** |
| SDK            | Python / JavaScript         | @momortis08-dev (Kaisar) |

**Team TSP:**
- **Nurlan (Kalb Master)** — Architect, Core Engineer, Captain
- **Kaisar (@momortis08-dev)** — API Gateway & Mobile Frontend Developer

---

## 🔐 Security

- Ed25519 oracle signature verification (on-chain)
- Replay protection (event processed flag + PDA)
- Escrow accounts via PDA
- Oracle private key isolated on edge device

---

## 🔗 Live Transaction (Devnet)

[View on Solana Devnet](https://explorer.solana.com/tx/5bdl9voegyh8?cluster=devnet) — confirmed in 2.3s

---

## 💻 How to Run (Demo)

**Live demo:** [qumyrsqa-core1.vercel.app](https://qumyrsqa-core1.vercel.app)

### Option 1: Web Dashboard + Python API
```bash
# 1. Start Python API Gateway
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --reload --port 8000

# 2. Open a new terminal, start Web Dashboard (React)
cd ..
npm install
npm run dev
```

### Option 2: Mobile App (Flutter)
```bash
cd flutter_client
flutter pub get
flutter run -d chrome
```

---

## 📦 SDK Example

```javascript
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
```

---

## 🧪 Demo Scenarios

✅ **Valid Event** — Trust Score: 87% | Status: SETTLED | Funds released
❌ **Invalid Event** — Trust Score: 45% | Status: BLOCKED | Funds frozen

---

## ⚡ Why Solana

Sub-second finality, ultra-low fees, ideal for high-frequency real-world events.

---

## 🧠 Innovation

**Execution Oracle for reality** — not just data delivery → autonomous settlement

---

## 🏆 Hackathon Status

- **Solana Frontier Hackathon** (Apr 6 – May 10)
- Project on Colosseum
- Weekly Update video: [YouTube](https://youtu.be/z3qcDvhTxAU)
- All partner references are to a representative demo scenario (Nice.like), not signed agreements
---

**Team TSP** · QumyrsqaCore
```

