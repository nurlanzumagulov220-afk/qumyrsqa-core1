/**
 * QumyrsqaCore SDK (lightweight)
 * Converts real-world events into on-chain settlements on Solana.
 */

export class Qumyrsqa {
  constructor({ clientId, apiKey, baseUrl = 'http://localhost:8080' }) {
    this.clientId = clientId;
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
  }

  async verify(payload) {
    const response = await fetch(`${this.baseUrl}/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': this.apiKey,
      },
      body: JSON.stringify({
        ...payload,
        client_id: this.clientId,
      }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Verification failed');
    }

    return response.json();
  }
}

export default Qumyrsqa;