# ⚪ QumyrsqaCore – Consistency Engine for Real-World Events (Solana Frontier Hackathon)

Мы превращаем физические события (аудит, handover) в **автономные действия смарт-контрактов** на Solana.  
Не «ещё один оракул», а **слой математической согласованности**, который даёт блокчейну зрение и исполнение.

---

## 🧠 Архитектура MVP

QR / Документ → Tamga (фиксация) → Tol (проверка консистентности) → Trust Score (кворум) → Solana Program (confirm_and_settle)
Если Trust > 80% → токены переходят с escrow (SETTLED)  
Если Trust ≤ 80% → средства заморожены (BLOCKED)

- **Offline-first ядро** на Go (Edge Hub Aksakal)
- **Solana Program** (Anchor) с Ed25519 подписью оракула и защитой от повторов
- **Дашборд** (React + Vite) для визуализации сценариев

---

## 🚀 Быстрый старт (демо)

```bash
git clone https://github.com/TSP-team/qumyrsqa-core.git
cd qumyrsqa-core/dashboard
npm install
npm run dev