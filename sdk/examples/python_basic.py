"""
Qumyrsqa Python SDK — примеры использования
Запуск: python python_basic.py
"""

import sys
sys.path.insert(0, '../python')

from qumyrsqa import QumyrsqaClient, GPSData, GyroscopeData

# ── 1. Базовое подключение ────────────────────────────────────────────────────

client = QumyrsqaClient(api_url='http://localhost:8000')

# Проверить что сервер работает
health = client.health()
print(f"Сервер: {health['status']}  |  Aksakal: {health['aksakal']}")

# ── 2. Регистрация и вход ─────────────────────────────────────────────────────

user = client.register(
    name='Aibek Seitkali',
    email='aibek@qumyrsqa.kz',
    password='secure_password_123',
)
print(f"Зарегистрирован: {user.name}  |  ID: {user.user_id}")
# Токен теперь установлен автоматически

# Или войти в существующий аккаунт:
# user = client.login('aibek@qumyrsqa.kz', 'secure_password_123')

# ── 3. Загрузка PDF документа ─────────────────────────────────────────────────

# Способ 1: загрузить файл
# upload = client.upload_document('invoice.pdf')
# document_hash = upload.document_hash

# Способ 2: хэшировать байты напрямую
document_hash = QumyrsqaClient.hash_string('DEMO_DOCUMENT_2026')
print(f"Хэш документа: {document_hash[:30]}...")

# ── 4. Верификация Tamga ──────────────────────────────────────────────────────

result = client.verify_tamga(
    device_id='server-node-almaty-01',
    gps=GPSData(lat=43.2551, lng=76.9126, accuracy=15.0),
    gyroscope=GyroscopeData(x=0.031, y=-0.018, z=0.004),
    document_hash=document_hash,
    wifi_mac=['AA:BB:CC:DD:EE:FF'],
)

print()
print('─' * 50)
print(f"Tamga ID:    {result.tamga_id}")
print(f"Статус:      {result.status}")
print(f"Trust Score: {result.trust_score * 100:.0f}%")
print(f"Консенсус:   {result.tol_sources.consensus}")
print(f"Сообщение:   {result.message}")
print(f"Solana:      {result.solana_explorer[:60]}...")
print(f"Latency:     {result.latency_ms}ms")
print('─' * 50)

if result.is_verified:
    print("✅ Документ верифицирован — средства разблокированы")
else:
    print("🚫 Верификация не пройдена — средства заморожены")

# ── 5. Личный кабинет ─────────────────────────────────────────────────────────

cabinet = client.get_cabinet()
stats = cabinet['stats']
print()
print(f"Кабинет {cabinet['user']['name']}:")
print(f"  Всего сканов: {stats['total_scans']}")
print(f"  Верифицировано: {stats['verified']}")
print(f"  Заблокировано:  {stats['blocked']}")

# ── 6. История и поиск ────────────────────────────────────────────────────────

# Получить запись по ID
record = client.get_tamga(result.tamga_id)
print(f"\nЗапись {record['tamga_id'][:8]}... создана: {record['created_at']}")

# Список последних записей
recent = client.list_tamga(limit=5)
print(f"Последние записи: {len(recent)} шт.")

# ── 7. Context manager (рекомендуется) ────────────────────────────────────────

with QumyrsqaClient('http://localhost:8000') as c:
    c.login('aibek@qumyrsqa.kz', 'secure_password_123')
    result = c.verify_tamga(
        device_id='auto-node-01',
        gps=GPSData(43.25, 76.95, 10),
        gyroscope=GyroscopeData(0.0, 0.0, 0.0),  # GPS есть, гироскоп нет
        document_hash=document_hash,
    )
    print(f"\nContext manager: {result.status} ({result.tol_sources.consensus})")
# HTTP-соединение закрывается автоматически
