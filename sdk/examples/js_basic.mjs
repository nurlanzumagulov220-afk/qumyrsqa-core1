/**
 * Qumyrsqa JavaScript SDK — примеры использования
 * Запуск: node js_basic.mjs  (Node 18+)
 */

// В реальном проекте: import { QumyrsqaSDK } from '@qumyrsqa/sdk'
import { QumyrsqaSDK } from '../javascript/src/index.ts'

const sdk = new QumyrsqaSDK({ apiUrl: 'http://localhost:8000' })

// ── 1. Health check ───────────────────────────────────────────────────────────

const health = await sdk.health()
console.log(`Сервер: ${health.status}  |  Aksakal: ${health.aksakal}`)

// ── 2. Регистрация ────────────────────────────────────────────────────────────

const user = await sdk.auth.register('Aibek Seitkali', 'aibek@qumyrsqa.kz', 'password123')
console.log(`Зарегистрирован: ${user.name}`)
// sdk токен установлен автоматически

// ── 3. Верификация Tamga ──────────────────────────────────────────────────────

const result = await sdk.verifyTamga({
  deviceId: 'web-client-almaty',
  gps: { lat: 43.2551, lng: 76.9126, accuracy: 15 },
  gyroscope: { x: 0.031, y: -0.018, z: 0.004 },
  documentHash: 'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
})

console.log(`
Tamga ID:    ${result.tamgaId}
Статус:      ${result.status}
Trust Score: ${(result.trustScore * 100).toFixed(0)}%
Консенсус:   ${result.tolSources.consensus}
Сообщение:   ${result.message}
Solana:      ${result.solanaExplorer.substring(0, 60)}...
`)

// ── 4. Cabinet ────────────────────────────────────────────────────────────────

const cabinet = await sdk.getCabinet()
console.log(`Кабинет ${cabinet.user.name}: ${cabinet.stats.totalScans} сканов`)
console.log(`  ✅ Верифицировано: ${cabinet.stats.verified}`)
console.log(`  🚫 Заблокировано:  ${cabinet.stats.blocked}`)

// ── 5. История ────────────────────────────────────────────────────────────────

const recent = await sdk.listTamga(5)
console.log(`\nПоследние записи:`)
recent.forEach(r => console.log(`  ${r.tamga_id.substring(0, 8)}...  ${r.status}  ${r.trust_score}`))

// ── 6. Logout ─────────────────────────────────────────────────────────────────

sdk.auth.logout()
console.log('\nToken очищен')
