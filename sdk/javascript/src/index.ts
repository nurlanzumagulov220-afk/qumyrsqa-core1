/**
 * Qumyrsqa Tamga SDK
 * Hardware-anchored data trust layer
 * https://qumyrsqa.io
 */

// ── Types ─────────────────────────────────────────────────────────────────────

export interface QumyrsqaConfig {
  /** Base URL of your Qumyrsqa backend. Default: http://localhost:8000 */
  apiUrl?: string
  /** JWT token (optional, can be set later via setToken) */
  token?: string
}

export interface GPSData {
  lat: number
  lng: number
  accuracy: number
}

export interface GyroscopeData {
  x: number
  y: number
  z: number
}

export interface TamgaRequest {
  deviceId: string
  gps: GPSData
  gyroscope: GyroscopeData
  wifiMac?: string[]
  documentHash: string
  timestamp?: string
}

export interface TolSources {
  document: boolean
  physical: boolean
  neighbor: boolean
  /** e.g. "3/3" or "1/3" */
  consensus: string
}

export interface TamgaResult {
  tamgaId: string
  trustScore: number
  livenessVerified: boolean
  consensusVerified: boolean
  status: 'VERIFIED' | 'BLOCKED'
  settlement: 'SETTLED' | 'BLOCKED'
  message: string
  solanaExplorer: string
  tolSources: TolSources
  latencyMs: number
  timestamp: string
  hashChain: string
  sparkplugEvent: string
  evidence: {
    deviceId: string
    geo: string
    file: string
  }
}

export interface UploadResult {
  documentHash: string
  filename: string
  sizeKb: number
}

export interface AuthUser {
  userId: string
  name: string
  email: string
  token: string
}

export interface CabinetStats {
  totalScans: number
  verified: number
  blocked: number
}

export interface HistoryItem {
  tamgaId: string
  status: string
  trustScore: number
  timestamp: string
}

export interface Cabinet {
  user: { name: string; email: string }
  stats: CabinetStats
  history: HistoryItem[]
}

export interface HealthStatus {
  status: string
  service: string
  version: string
  aksakal: 'live' | 'offline'
}

export class QumyrsqaError extends Error {
  constructor(
    message: string,
    public readonly statusCode?: number,
  ) {
    super(message)
    this.name = 'QumyrsqaError'
  }
}

// ── SDK ───────────────────────────────────────────────────────────────────────

export class QumyrsqaSDK {
  private apiUrl: string
  private token: string | null

  constructor(config: QumyrsqaConfig = {}) {
    this.apiUrl = (config.apiUrl ?? 'http://localhost:8000').replace(/\/$/, '')
    this.token = config.token ?? null
  }

  /** Set JWT token (after login/register) */
  setToken(token: string): void {
    this.token = token
  }

  /** Remove JWT token (logout) */
  clearToken(): void {
    this.token = null
  }

  private get authHeader(): Record<string, string> {
    return this.token ? { Authorization: `Bearer ${this.token}` } : {}
  }

  private async request<T>(method: string, path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${this.apiUrl}${path}`, {
      method,
      headers: { 'Content-Type': 'application/json', ...this.authHeader },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    })
    const data = await res.json()
    if (!res.ok) {
      throw new QumyrsqaError(data?.detail ?? `HTTP ${res.status}`, res.status)
    }
    return data as T
  }

  // ── System ──────────────────────────────────────────────────────────────────

  /** Check server health + aksakal (Go core) status */
  async health(): Promise<HealthStatus> {
    return this.request<HealthStatus>('GET', '/health')
  }

  // ── Documents ───────────────────────────────────────────────────────────────

  /**
   * Upload a PDF and get its SHA-256 hash.
   * Use the returned documentHash in verifyTamga().
   *
   * @example
   * const file = document.querySelector('input[type=file]').files[0]
   * const { documentHash } = await sdk.uploadDocument(file)
   */
  async uploadDocument(file: File): Promise<UploadResult> {
    const form = new FormData()
    form.append('file', file)

    const res = await fetch(`${this.apiUrl}/upload-document`, {
      method: 'POST',
      headers: this.authHeader,
      body: form,
    })
    const data = await res.json()
    if (!res.ok) throw new QumyrsqaError(data?.detail ?? `HTTP ${res.status}`, res.status)

    return {
      documentHash: data.document_hash,
      filename: data.filename,
      sizeKb: data.size_kb,
    }
  }

  // ── Tamga ────────────────────────────────────────────────────────────────────

  /**
   * Run Tol Consensus verification and create a Tamga record.
   *
   * Requires: device sensors + document hash.
   * Returns: trust score, settlement status, Solana TX link.
   *
   * @example
   * const result = await sdk.verifyTamga({
   *   deviceId: 'device-001',
   *   gps: { lat: 43.25, lng: 76.95, accuracy: 10 },
   *   gyroscope: { x: 0.031, y: -0.018, z: 0.004 },
   *   documentHash: 'sha256:abc123...',
   * })
   * console.log(result.status)        // 'VERIFIED'
   * console.log(result.trustScore)    // 0.87
   * console.log(result.solanaExplorer) // https://explorer.solana.com/...
   */
  async verifyTamga(req: TamgaRequest): Promise<TamgaResult> {
    const raw = await this.request<Record<string, unknown>>('POST', '/verify-tamga', {
      device_id: req.deviceId,
      gps: req.gps,
      gyroscope: req.gyroscope,
      wifi_mac: req.wifiMac ?? [],
      timestamp: req.timestamp ?? new Date().toISOString(),
      document_hash: req.documentHash,
    })

    const src = raw.tol_sources as Record<string, unknown>
    const evi = raw.evidence as Record<string, unknown>

    return {
      tamgaId: raw.tamga_id as string,
      trustScore: raw.trust_score as number,
      livenessVerified: raw.liveness_verified as boolean,
      consensusVerified: raw.consensus_verified as boolean,
      status: raw.status as 'VERIFIED' | 'BLOCKED',
      settlement: raw.settlement as 'SETTLED' | 'BLOCKED',
      message: raw.message as string,
      solanaExplorer: raw.solana_explorer as string,
      tolSources: {
        document: src.document as boolean,
        physical: src.physical as boolean,
        neighbor: src.neighbor as boolean,
        consensus: src.consensus as string,
      },
      latencyMs: raw.latency_ms as number,
      timestamp: raw.timestamp as string,
      hashChain: raw.hash_chain as string,
      sparkplugEvent: raw.sparkplug_event as string,
      evidence: {
        deviceId: evi.device_id as string,
        geo: evi.geo as string,
        file: evi.file as string,
      },
    }
  }

  /** Get a previously created Tamga record by ID */
  async getTamga(tamgaId: string): Promise<Record<string, unknown>> {
    return this.request('GET', `/verify-tamga/${tamgaId}`)
  }

  /** List last N tamga records */
  async listTamga(limit = 20): Promise<Record<string, unknown>[]> {
    return this.request('GET', `/tamga-list?limit=${limit}`)
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  /**
   * Register a new account. Automatically sets the token.
   *
   * @example
   * const user = await sdk.auth.register('Aibek', 'aibek@kz.io', 'password123')
   * // sdk.token is now set automatically
   */
  readonly auth = {
    register: async (name: string, email: string, password: string): Promise<AuthUser> => {
      const d = await this.request<Record<string, string>>('POST', '/auth/register', {
        name, email, password,
      })
      this.setToken(d.token)
      return { userId: d.user_id, name: d.name, email: d.email, token: d.token }
    },

    login: async (email: string, password: string): Promise<AuthUser> => {
      const d = await this.request<Record<string, string>>('POST', '/auth/login', {
        email, password,
      })
      this.setToken(d.token)
      return { userId: d.user_id, name: d.name, email: d.email, token: d.token }
    },

    logout: (): void => {
      this.clearToken()
    },
  }

  // ── Cabinet ──────────────────────────────────────────────────────────────────

  /**
   * Get personal cabinet: scan history + stats.
   * Requires authentication (call auth.login first).
   */
  async getCabinet(): Promise<Cabinet> {
    const d = await this.request<Record<string, unknown>>('GET', '/cabinet')
    const stats = d.stats as Record<string, number>
    const history = d.history as Array<Record<string, unknown>>

    return {
      user: d.user as { name: string; email: string },
      stats: {
        totalScans: stats.total_scans,
        verified: stats.verified,
        blocked: stats.blocked,
      },
      history: history.map((h) => ({
        tamgaId: h.tamga_id as string,
        status: h.status as string,
        trustScore: h.trust_score as number,
        timestamp: h.timestamp as string,
      })),
    }
  }
}

// Default export
export default QumyrsqaSDK
