# QumyrsqaCore — Hackathon Quick Start

> Solana Frontier Hackathon · METAFORRA + Open Track

## In 10 Seconds

**Problem**: Businesses lose 12% to fraud + 10% to manual verification.
**Solution**: Hardware-anchored event fingerprint → automatic Solana settlement.
**Result**: Fraud → 0%. Savings → $2.10/event.

## Full Stack

```
Go (Aksakal)     — Edge node, Tamga signing
Python (FastAPI) — API Gateway, Tol Consensus, JWT Auth
Rust (Anchor)    — Solana smart contract
React + TS       — Web dashboard
Flutter          — Mobile app (iOS/Android/Web)
TypeScript SDK   — @qumyrsqa/sdk
Python SDK       — pip install qumyrsqa
```

## Run in 3 Minutes

```bash
# Backend
cd backend && bash start.sh
# → http://localhost:8000/docs (Swagger UI)

# Flutter Web
cd flutter_client
flutter build web --no-tree-shake-icons
cd build/web && python3 -m http.server 9000
# → http://localhost:9000

# React Dashboard
npm install && npm run dev
# → http://localhost:5173
```

## Demo Flow

```
Courier scans delivery PDF on phone
GPS: 43.25, 76.95 | Gyro: real device
         ↓
Tol: 3/3 → Trust 87% → VERIFIED
         ↓
100 USDC → Supplier wallet (Solana devnet)
```

## SDK — 10 Minute Integration

```python
from qumyrsqa import QumyrsqaClient, GPSData, GyroscopeData

with QumyrsqaClient('http://localhost:8000') as c:
    c.login('you@company.kz', 'password')
    result = c.verify_tamga(
        device_id='node-01',
        gps=GPSData(43.25, 76.95, 10),
        gyroscope=GyroscopeData(0.031, -0.018, 0.004),
        document_hash=c.hash_string('invoice #1042'),
    )
    print(result.status)  # VERIFIED
```

## Team

**Nurlan Zhumagulov (Kalb Master)** — Founder, Go/Rust/Architecture
**Kaisar** — Python API Gateway, Flutter Mobile, SDK

📍 Almaty, Kazakhstan · Telegram: @takkirshah
