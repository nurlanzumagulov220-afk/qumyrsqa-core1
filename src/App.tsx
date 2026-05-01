import React, { useState } from 'react';

const Dashboard: React.FC = () => {
  const [events, setEvents] = useState<any[]>([]);
  const [txSig, setTxSig] = useState<string | null>(null);

  // --- Хороший сценарий (SETTLED) ---
  const handleGoodEvent = () => {
    const newEvent = {
      id: Date.now().toString(),
      tamga: 'uuidv7-9f2c...',
      riskBefore: 0.62,
      riskAfter: 0.07,
      trustScore: 88,
      status: 'SETTLED',
    };
    setEvents((prev) => [newEvent, ...prev]);

    // эмулируем подпись транзакции
    const fakeSig = '5' + Math.random().toString(36).substring(2, 15);
    setTxSig(fakeSig);
  };

  // --- Плохой сценарий (BLOCKED) ---
  const handleBadEvent = () => {
    const newEvent = {
      id: Date.now().toString(),
      tamga: 'uuidv7-bad...',
      riskBefore: 0.61,
      riskAfter: 0.58,
      trustScore: 45,
      status: 'BLOCKED',
    };
    setEvents((prev) => [newEvent, ...prev]);
    setTxSig(null); // транзакции нет — деньги заморожены
  };

  return (
    <div style={{ display: 'flex', height: '100vh', fontFamily: 'monospace', background: '#111', color: '#fff' }}>
      {/* Левая панель */}
      <div style={{ flex: 2, padding: 20, borderRight: '1px solid #333' }}>
        <h1>⚪ QumyrsqaCore Visualizer</h1>

        {/* шаги пайплайна */}
        <div>
          {['QR Scan', 'Tamga', 'Tol', 'Trust', 'Solana TX'].map((step) => (
            <div key={step} style={{ padding: 8, background: '#222', margin: 4, borderRadius: 4 }}>
              {step}
            </div>
          ))}
        </div>

        {/* Кнопки двух сценариев */}
        <button
          onClick={handleGoodEvent}
          style={{
            marginTop: 20,
            padding: '10px 20px',
            background: '#4caf50',
            color: '#fff',
            border: 'none',
            borderRadius: 4,
            cursor: 'pointer',
            marginRight: 10,
          }}
        >
          ✅ Simulate Good Audit
        </button>

        <button
          onClick={handleBadEvent}
          style={{
            marginTop: 20,
            padding: '10px 20px',
            background: '#f44336',
            color: '#fff',
            border: 'none',
            borderRadius: 4,
            cursor: 'pointer',
          }}
        >
          ❌ Simulate Bad Audit
        </button>

        {/* Показываем ссылку на Solana Explorer только если есть транзакция */}
        {txSig && (
          <p style={{ color: '#4caf50' }}>
            ✅ Solana TX:{' '}
            <a
              href={`https://explorer.solana.com/tx/${txSig}?cluster=devnet`}
              target="_blank"
              style={{ color: '#4caf50' }}
            >
              {txSig}
            </a>
          </p>
        )}
      </div>

      {/* Правая панель — Risk Ledger */}
      <div style={{ flex: 1, padding: 20, background: '#0a0a0a' }}>
        <h2>Risk Reduction Ledger</h2>
        {events.length === 0 && <p style={{ color: '#666' }}>Нет событий. Нажми на симуляцию.</p>}
        {events.map((ev) => (
          <div key={ev.id} style={{ background: '#1a1a1a', padding: 10, marginBottom: 10, borderRadius: 4 }}>
            <div>Tamga: {ev.tamga}</div>
            <div>Risk: {ev.riskBefore} → {ev.riskAfter}</div>

            {/* Trust Score с подсказкой (наведи мышку) */}
            <div title="0.6×Consensus + 0.3×History + 0.1×Context">
              Trust Score: {ev.trustScore}% ⓘ
            </div>

            <div
              style={{
                color: ev.status === 'SETTLED' ? '#4caf50' : '#f44336',
                fontWeight: 'bold',
              }}
            >
              {ev.status}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Dashboard;