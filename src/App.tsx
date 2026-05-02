import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const Dashboard: React.FC = () => {
  const [events, setEvents] = useState<any[]>([]);
  const [txSig, setTxSig] = useState<string | null>(null);
  const [lastStep, setLastStep] = useState(0); // для анимации шагов
  const [latency, setLatency] = useState<string | null>(null);

  const handleGoodEvent = () => {
    setLastStep(0);
    const timer = setInterval(() => {
      setLastStep(prev => {
        if (prev >= 5) {
          clearInterval(timer);
          return prev;
        }
        return prev + 1;
      });
    }, 400);

    const start = Date.now();
    setTimeout(() => {
      const newEvent = {
        id: Date.now().toString(),
        tamga: 'uuidv7-9f2c...',
        riskBefore: 0.62,
        riskAfter: 0.07,
        trustScore: 88,
        status: 'SETTLED',
      };
      setEvents((prev) => [newEvent, ...prev]);
      const fakeSig = '5' + Math.random().toString(36).substring(2, 15);
      setTxSig(fakeSig);
      setLatency((Date.now() - start) / 1000 + 's');
    }, 2300);
  };

  const handleBadEvent = () => {
    setLastStep(0);
    const timer = setInterval(() => {
      setLastStep(prev => {
        if (prev >= 4) {
          clearInterval(timer);
          return prev;
        }
        return prev + 1;
      });
    }, 400);

    setTimeout(() => {
      const newEvent = {
        id: Date.now().toString(),
        tamga: 'uuidv7-bad...',
        riskBefore: 0.61,
        riskAfter: 0.58,
        trustScore: 45,
        status: 'BLOCKED',
      };
      setEvents((prev) => [newEvent, ...prev]);
      setTxSig(null);
      setLatency('—');
    }, 1900);
  };

  const steps = ['QR Scan', 'Tamga', 'Tol', 'Trust', 'Solana TX'];

  const getTrustColor = (score: number) => {
    if (score > 80) return '#4caf50';
    if (score > 50) return '#ff9800';
    return '#f44336';
  };

  return (
    <div style={{ display: 'flex', height: '100vh', fontFamily: 'Inter, system-ui, sans-serif', background: '#0e0e0f', color: '#eaeaea' }}>
      {/* Левая панель */}
      <div style={{ flex: 2, padding: '2rem', borderRight: '1px solid #2a2a2d' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 30 }}>
          <span style={{ fontSize: 32 }}>⚪</span>
          <h1 style={{ margin: 0, fontWeight: 600, fontSize: '1.8rem' }}>QumyrsqaCore</h1>
          <span style={{ background: '#1f1f22', padding: '4px 10px', borderRadius: 6, fontSize: '0.8rem', color: '#aaa' }}>Solana Frontier</span>
        </div>

        {/* Анимированная цепочка */}
        <div style={{ marginBottom: 30 }}>
          {steps.map((step, i) => (
            <motion.div
              key={step}
              initial={{ opacity: 0, x: -20 }}
              animate={lastStep >= i ? { opacity: 1, x: 0 } : {}}
              transition={{ duration: 0.3 }}
              style={{
                padding: '10px 16px',
                background: lastStep >= i ? '#1f1f22' : '#161618',
                margin: '4px 0',
                borderRadius: 6,
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                borderLeft: lastStep >= i ? `3px solid ${i === 5 ? '#4caf50' : '#6c5ce7'}` : '3px solid transparent',
              }}
            >
              <span>{step}</span>
              {lastStep >= i && <span style={{ color: '#4caf50' }}>✓</span>}
            </motion.div>
          ))}
        </div>

        {/* Кнопки */}
        <div style={{ display: 'flex', gap: 12 }}>
          <button onClick={handleGoodEvent} style={{ flex: 1, padding: '12px', background: '#4caf50', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
            ✅ Simulate Good Audit
          </button>
          <button onClick={handleBadEvent} style={{ flex: 1, padding: '12px', background: '#f44336', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
            ❌ Simulate Bad Audit
          </button>
        </div>

        {/* Транзакция */}
        <AnimatePresence>
          {txSig && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} style={{ marginTop: 20, background: '#1b2e1b', padding: 10, borderRadius: 6 }}>
              <span style={{ color: '#4caf50' }}>✅ Solana TX confirmed</span><br />
              <a href={`https://explorer.solana.com/tx/${txSig}?cluster=devnet`} target="_blank" style={{ color: '#80cbc4', fontSize: '0.9rem' }}>{txSig}</a>
              {latency && <div style={{ color: '#888', marginTop: 4 }}>⏱ Latency to settlement: {latency}</div>}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Правая панель — Risk Ledger */}
      <div style={{ flex: 1, padding: '2rem', background: '#121214' }}>
        <h2 style={{ fontWeight: 500, fontSize: '1.3rem', marginBottom: 20 }}>Risk Reduction Ledger</h2>
        {events.length === 0 && <p style={{ color: '#555' }}>Нет событий. Нажми на симуляцию.</p>}
        {events.map((ev) => (
          <motion.div
            key={ev.id}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            style={{ background: '#1a1a1d', padding: 16, marginBottom: 12, borderRadius: 8, border: `1px solid ${ev.status === 'SETTLED' ? '#2e4a2e' : '#4a2e2e'}` }}
          >
            <div style={{ fontSize: '0.8rem', color: '#888', marginBottom: 6 }}>Tamga: {ev.tamga}</div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: '0.9rem' }}>Risk: {ev.riskBefore} → {ev.riskAfter}</div>
                <div style={{ fontSize: '0.9rem' }}>Trust Score: {ev.trustScore}%</div>
              </div>
              <div style={{ position: 'relative', width: 60, height: 60 }}>
                <svg viewBox="0 0 36 36" style={{ width: '100%', transform: 'rotate(-90deg)' }}>
                  <path d="M18 2.08 a 15.92 15.92 0 0 1 0 31.84" fill="none" stroke="#333" strokeWidth="3" />
                  <motion.path
                    d="M18 2.08 a 15.92 15.92 0 0 1 0 31.84"
                    fill="none"
                    stroke={getTrustColor(ev.trustScore)}
                    strokeWidth="3"
                    strokeDasharray={`${ev.trustScore} 100`}
                    initial={{ strokeDasharray: '0 100' }}
                    animate={{ strokeDasharray: `${ev.trustScore} 100` }}
                    transition={{ duration: 0.8 }}
                  />
                </svg>
                <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', fontSize: '0.75rem', fontWeight: 700, color: getTrustColor(ev.trustScore) }}>{ev.trustScore}%</div>
              </div>
            </div>
            <div style={{ marginTop: 8, fontWeight: 600, color: ev.status === 'SETTLED' ? '#4caf50' : '#f44336' }}>
              {ev.status === 'SETTLED' ? '💸 SETTLED' : '🔒 BLOCKED'}
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
};

export default Dashboard;