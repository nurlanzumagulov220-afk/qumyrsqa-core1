import { Qumyrsqa } from './qumyrsqa.js';

const qr = new Qumyrsqa({
  clientId: 'demo',
  apiKey: 'demo_key',
  baseUrl: 'http://localhost:8080',
});

async function run() {
  try {
    console.log('🚀 Submitting event...');
    const event = await qr.verify({
      document_hash: 'sha256:test123',
      document_type: 'legal_audit',
      counterparty_id: 'KZ-ENT-001',
    });

    console.log('✅ Verified:', event.status);
    console.log('🧠 Trust Score:', event.trust_score);
    console.log('🔗 TX:', event.tx_hash);
  } catch (err) {
    console.error('❌ Verification failed:', err.message);
  }
}

run();