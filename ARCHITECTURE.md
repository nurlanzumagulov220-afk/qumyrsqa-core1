# QumyrsqaCore — Full System Architecture

> *Trust is computed locally, then anchored globally.*

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Edge Node | Go (Aksakal) | Event ingestion, Tamga signing, CRDT sync |
| API Gateway | Python / FastAPI | Sensor validation, Auth, Tol Consensus |
| Smart Contract | Rust / Anchor | Auto-settlement on Solana |
| Web Dashboard | React + TypeScript | Event visualization |
| Mobile App | Flutter | Document scan, GPS liveness, sensors |
| SDK | TypeScript + Python | Developer integration layer |

## System Flow

```
[Flutter Mobile: GPS + Gyro + PDF hash]
        ↓
[Python FastAPI: JWT Auth + Tol Consensus]
  Source 1: document_hash non-empty
  Source 2: GPS non-zero AND gyro non-zero
  Source 3: virtual neighbor within 0.01°
  → 2/3 = 0.87 VERIFIED | <2/3 = 0.45 BLOCKED
        ↓
[Go Aksakal: Ed25519 Tamga signature + CRDT]
        ↓
[Solana Rust/Anchor: auto-transfer or freeze]
```

## GPS Validation Rules

| State | Result |
|-------|--------|
| Real GPS + Gyro working | VERIFIED 87% |
| GPS denied (0,0) | BLOCKED 45% |
| GPS ok + Gyro zero | BLOCKED 45% |
| Both zero | BLOCKED 45% |

## Repository Structure

```
qumyrsqa-core1/
├── src/              ← React dashboard
├── backend/          ← Python FastAPI (Auth + Tol Consensus)
├── flutter_client/   ← Flutter Mobile/Web app
├── sdk/javascript/   ← TypeScript SDK
├── sdk/python/       ← Python SDK
└── docs/             ← Architecture + Hackathon guide
```
