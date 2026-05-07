"""
Qumyrsqa Tamga SDK — Python Client
Hardware-anchored data trust layer
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

import httpx


class QumyrsqaError(Exception):
    def __init__(self, message: str, status_code: int | None = None):
        super().__init__(message)
        self.status_code = status_code


# ── Data Classes ──────────────────────────────────────────────────────────────

@dataclass
class GPSData:
    lat: float
    lng: float
    accuracy: float = 0.0


@dataclass
class GyroscopeData:
    x: float
    y: float
    z: float


@dataclass
class TolSources:
    document: bool
    physical: bool
    neighbor: bool
    consensus: str


@dataclass
class TamgaResult:
    tamga_id: str
    trust_score: float
    liveness_verified: bool
    consensus_verified: bool
    status: str          # "VERIFIED" | "BLOCKED"
    settlement: str      # "SETTLED" | "BLOCKED"
    message: str
    solana_explorer: str
    tol_sources: TolSources
    latency_ms: int
    timestamp: str
    hash_chain: str
    sparkplug_event: str
    evidence: dict[str, str]

    @property
    def is_verified(self) -> bool:
        return self.settlement == "SETTLED"


@dataclass
class UploadResult:
    document_hash: str
    filename: str
    size_kb: float


@dataclass
class AuthUser:
    user_id: str
    name: str
    email: str
    token: str


# ── Client ────────────────────────────────────────────────────────────────────

class QumyrsqaClient:
    """
    Qumyrsqa Tamga Python SDK.

    Usage::

        from qumyrsqa import QumyrsqaClient, GPSData, GyroscopeData

        with QumyrsqaClient() as client:
            user = client.login("you@example.com", "password")

            upload = client.upload_document("invoice.pdf")

            result = client.verify_tamga(
                device_id="server-node-01",
                gps=GPSData(lat=43.25, lng=76.95, accuracy=10),
                gyroscope=GyroscopeData(x=0.031, y=-0.018, z=0.004),
                document_hash=upload.document_hash,
            )

            print(result.status)         # VERIFIED
            print(result.trust_score)    # 0.87
            print(result.solana_explorer)
    """

    def __init__(
        self,
        api_url: str = "http://localhost:8000",
        token: Optional[str] = None,
        timeout: float = 30.0,
    ):
        self.api_url = api_url.rstrip("/")
        self.token = token
        self._http = httpx.Client(timeout=timeout)

    # ── Internal helpers ───────────────────────────────────────────────────────

    def _headers(self) -> dict[str, str]:
        if self.token:
            return {"Authorization": f"Bearer {self.token}"}
        return {}

    def _get(self, path: str) -> Any:
        r = self._http.get(f"{self.api_url}{path}", headers=self._headers())
        self._raise(r)
        return r.json()

    def _post(self, path: str, data: dict) -> Any:
        r = self._http.post(f"{self.api_url}{path}", json=data, headers=self._headers())
        self._raise(r)
        return r.json()

    def _raise(self, r: httpx.Response) -> None:
        if not r.is_success:
            try:
                detail = r.json().get("detail", f"HTTP {r.status_code}")
            except Exception:
                detail = f"HTTP {r.status_code}"
            raise QumyrsqaError(detail, r.status_code)

    # ── System ─────────────────────────────────────────────────────────────────

    def health(self) -> dict:
        """Check server health and aksakal (Go core) status."""
        return self._get("/health")

    # ── Documents ──────────────────────────────────────────────────────────────

    def upload_document(self, filepath: str | Path) -> UploadResult:
        """
        Upload a PDF file and get its SHA-256 hash.

        Args:
            filepath: Path to PDF file on disk.

        Returns:
            UploadResult with document_hash, filename, size_kb.

        Example::

            result = client.upload_document("invoice.pdf")
            print(result.document_hash)  # sha256:abc123...
        """
        path = Path(filepath)
        content = path.read_bytes()
        headers = self._headers()

        r = self._http.post(
            f"{self.api_url}/upload-document",
            files={"file": (path.name, content, "application/pdf")},
            headers=headers,
        )
        self._raise(r)
        d = r.json()
        return UploadResult(
            document_hash=d["document_hash"],
            filename=d["filename"],
            size_kb=d["size_kb"],
        )

    @staticmethod
    def hash_bytes(data: bytes) -> str:
        """Compute SHA-256 of raw bytes. Useful if you already have file content."""
        return f"sha256:{hashlib.sha256(data).hexdigest()}"

    @staticmethod
    def hash_string(text: str) -> str:
        """Compute SHA-256 of a string."""
        return f"sha256:{hashlib.sha256(text.encode()).hexdigest()}"

    # ── Tamga ──────────────────────────────────────────────────────────────────

    def verify_tamga(
        self,
        device_id: str,
        gps: GPSData,
        gyroscope: GyroscopeData,
        document_hash: str,
        wifi_mac: Optional[list[str]] = None,
        timestamp: Optional[str] = None,
    ) -> TamgaResult:
        """
        Run Tol Consensus verification and create a Tamga record.

        The three consensus sources:
          1. Document  — document_hash is non-empty
          2. Physical  — GPS is non-zero AND gyroscope is non-zero
          3. Neighbor  — virtual neighbor within 0.01° of GPS

        2/3 sources → VERIFIED (0.87), else BLOCKED (0.45).

        Args:
            device_id:      Unique device or node identifier.
            gps:            GPS coordinates. Use GPSData(0, 0, 0) if unavailable.
            gyroscope:      Gyroscope readings. Use GyroscopeData(0, 0, 0) if unavailable.
            document_hash:  SHA-256 hash (from upload_document or hash_bytes).
            wifi_mac:       List of WiFi MAC addresses (optional).
            timestamp:      ISO 8601 timestamp (default: now).

        Returns:
            TamgaResult with status, trust_score, Solana explorer link, etc.
        """
        d = self._post("/verify-tamga", {
            "device_id": device_id,
            "gps": {"lat": gps.lat, "lng": gps.lng, "accuracy": gps.accuracy},
            "gyroscope": {"x": gyroscope.x, "y": gyroscope.y, "z": gyroscope.z},
            "wifi_mac": wifi_mac or [],
            "timestamp": timestamp or datetime.now().isoformat(),
            "document_hash": document_hash,
        })

        return TamgaResult(
            tamga_id=d["tamga_id"],
            trust_score=d["trust_score"],
            liveness_verified=d["liveness_verified"],
            consensus_verified=d["consensus_verified"],
            status=d["status"],
            settlement=d["settlement"],
            message=d["message"],
            solana_explorer=d["solana_explorer"],
            tol_sources=TolSources(**d["tol_sources"]),
            latency_ms=d["latency_ms"],
            timestamp=d["timestamp"],
            hash_chain=d["hash_chain"],
            sparkplug_event=d["sparkplug_event"],
            evidence=d["evidence"],
        )

    def get_tamga(self, tamga_id: str) -> dict:
        """Retrieve a Tamga record by its ID."""
        return self._get(f"/verify-tamga/{tamga_id}")

    def list_tamga(self, limit: int = 20) -> list[dict]:
        """List the most recent Tamga records."""
        return self._get(f"/tamga-list?limit={limit}")

    # ── Auth ───────────────────────────────────────────────────────────────────

    def register(self, name: str, email: str, password: str) -> AuthUser:
        """
        Register a new account. Automatically sets self.token.

        Example::

            user = client.register("Aibek", "aibek@kz.io", "pass123")
            print(user.token)
        """
        d = self._post("/auth/register", {"name": name, "email": email, "password": password})
        self.token = d["token"]
        return AuthUser(user_id=d["user_id"], name=d["name"], email=d["email"], token=d["token"])

    def login(self, email: str, password: str) -> AuthUser:
        """
        Login and automatically set self.token.

        Example::

            user = client.login("aibek@kz.io", "pass123")
        """
        d = self._post("/auth/login", {"email": email, "password": password})
        self.token = d["token"]
        return AuthUser(user_id=d["user_id"], name=d["name"], email=d["email"], token=d["token"])

    def logout(self) -> None:
        """Clear the stored JWT token."""
        self.token = None

    # ── Cabinet ────────────────────────────────────────────────────────────────

    def get_cabinet(self) -> dict:
        """
        Get personal cabinet: scan history and statistics.
        Requires authentication (call login first).
        """
        return self._get("/cabinet")

    # ── Context manager ────────────────────────────────────────────────────────

    def close(self) -> None:
        self._http.close()

    def __enter__(self) -> "QumyrsqaClient":
        return self

    def __exit__(self, *_: Any) -> None:
        self.close()
