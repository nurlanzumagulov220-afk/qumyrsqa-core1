import hashlib
import json
import random
import time
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional

import bcrypt
import httpx
from fastapi import Depends, FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import engine, get_db
import models

models.Base.metadata.create_all(bind=engine)


def _migrate():
    with engine.connect() as conn:
        for stmt in [
            "ALTER TABLE tamga_records ADD COLUMN user_id TEXT",
            "ALTER TABLE tamga_records ADD COLUMN status TEXT",
        ]:
            try:
                conn.execute(text(stmt))
                conn.commit()
            except Exception:
                pass


_migrate()

import os
_JWT_SECRET = os.environ.get("JWT_SECRET", "change-me-in-production")
_JWT_ALG = "HS256"
_security = HTTPBearer(auto_error=False)
_AKSAKAL_URL = os.environ.get("AKSAKAL_URL", "http://localhost:8080")

app = FastAPI(
    title="Qumyrsqa Tamga API",
    description="Hardware-anchored data trust layer — Demo PoC",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Auth helpers ─────────────────────────────────────────────────────────────

def _create_token(user_id: str) -> str:
    exp = datetime.now(timezone.utc) + timedelta(days=30)
    return jwt.encode({"sub": user_id, "exp": exp}, _JWT_SECRET, algorithm=_JWT_ALG)


def _decode_token(token: str) -> Optional[str]:
    try:
        return jwt.decode(token, _JWT_SECRET, algorithms=[_JWT_ALG]).get("sub")
    except JWTError:
        return None


def _get_optional_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(_security),
    db: Session = Depends(get_db),
) -> Optional[models.User]:
    if not creds:
        return None
    uid = _decode_token(creds.credentials)
    if not uid:
        return None
    return db.query(models.User).filter(models.User.user_id == uid).first()


def _get_current_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(_security),
    db: Session = Depends(get_db),
) -> models.User:
    if not creds:
        raise HTTPException(401, "Not authenticated")
    uid = _decode_token(creds.credentials)
    if not uid:
        raise HTTPException(401, "Invalid or expired token")
    user = db.query(models.User).filter(models.User.user_id == uid).first()
    if not user:
        raise HTTPException(401, "User not found")
    return user


# ── Pydantic Schemas ─────────────────────────────────────────────────────────

class GPS(BaseModel):
    lat: float
    lng: float
    accuracy: float


class Gyroscope(BaseModel):
    x: float
    y: float
    z: float


class TamgaRequest(BaseModel):
    device_id: str
    gps: GPS
    gyroscope: Gyroscope
    wifi_mac: List[str]
    timestamp: str
    document_hash: str


class RegisterRequest(BaseModel):
    email: str
    name: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


# ── Aksakal (Go core) bridge ──────────────────────────────────────────────────

async def _call_aksakal(req: "TamgaRequest") -> Optional[dict]:
    """Call Go Aksakal core. Returns None if unavailable (fallback to Python)."""
    gyro = req.gyroscope
    gyro_noise = f"{gyro.x:.4f},{gyro.y:.4f},{gyro.z:.4f}"
    payload = {
        "device_id": req.device_id,
        "gps_lat": req.gps.lat,
        "gps_lon": req.gps.lng,
        "gyro_noise": gyro_noise,
        "document_hash": req.document_hash,
    }
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{_AKSAKAL_URL}/internal/tamga",
                json=payload,
                timeout=2.0,
            )
        if resp.is_success:
            return resp.json()
    except Exception:
        pass
    return None


# ── Tol Consensus ─────────────────────────────────────────────────────────────

def _mock_solana_tx() -> str:
    chars = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return "".join(random.choices(chars, k=44))


def tol_consensus(req: TamgaRequest) -> dict:
    doc_verified = bool(req.document_hash and req.document_hash.strip())

    gyro = req.gyroscope
    liveness = not (gyro.x == 0.0 and gyro.y == 0.0 and gyro.z == 0.0)
    geo_valid = not (req.gps.lat == 0.0 and req.gps.lng == 0.0)
    physical_verified = liveness and geo_valid

    if not geo_valid or not liveness:
        neighbor_verified = False
    else:
        n_lat = req.gps.lat + random.uniform(-0.001, 0.001)
        n_lon = req.gps.lng + random.uniform(-0.001, 0.001)
        neighbor_verified = abs(n_lat - req.gps.lat) < 0.01 and abs(n_lon - req.gps.lng) < 0.01

    count = sum([doc_verified, physical_verified, neighbor_verified])
    consensus_ok = count >= 2
    trust_score = 0.87 if consensus_ok else 0.45

    if trust_score >= 0.80:
        status, settlement, message = "VERIFIED", "SETTLED", "Funds Released"
    else:
        status, settlement, message = "BLOCKED", "BLOCKED", "Funds Frozen"

    tx = _mock_solana_tx()
    return {
        "trust_score": trust_score,
        "liveness_verified": physical_verified,
        "consensus_verified": consensus_ok,
        "status": status,
        "settlement": settlement,
        "message": message,
        "solana_tx": tx,
        "solana_explorer": f"https://explorer.solana.com/tx/{tx}?cluster=devnet",
        "tol_sources": {
            "document": doc_verified,
            "physical": physical_verified,
            "neighbor": neighbor_verified,
            "consensus": f"{count}/3",
        },
        "evidence": {
            "device_id": req.device_id,
            "geo": f"{req.gps.lat:.4f}, {req.gps.lng:.4f}",
            "file": "invoice_demo.pdf",
        },
    }


def build_hash_chain(req: TamgaRequest) -> str:
    raw = req.device_id + json.dumps(req.gps.model_dump(), sort_keys=True) + req.timestamp + req.document_hash
    return hashlib.sha256(raw.encode()).hexdigest()


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", tags=["System"])
async def health_check():
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get("http://localhost:8080/health", timeout=2.0)
        aksakal = "live" if resp.is_success else "offline"
    except Exception:
        aksakal = "offline"
    return {"status": "ok", "service": "Qumyrsqa Tamga", "version": "2.0.0", "aksakal": aksakal}


@app.post("/upload-document", tags=["Documents"])
async def upload_document(file: UploadFile = File(...)):
    content = await file.read()
    hash_hex = hashlib.sha256(content).hexdigest()
    return {
        "document_hash": f"sha256:{hash_hex}",
        "filename": file.filename,
        "size_kb": round(len(content) / 1024, 1),
    }


@app.post("/auth/register", tags=["Auth"])
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == body.email).first():
        raise HTTPException(400, "Email already registered")
    pw_hash = bcrypt.hashpw(body.password.encode(), bcrypt.gensalt()).decode()
    user = models.User(
        user_id=str(uuid.uuid4()),
        email=body.email,
        name=body.name,
        password_hash=pw_hash,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"user_id": user.user_id, "name": user.name, "email": user.email, "token": _create_token(user.user_id)}


@app.post("/auth/login", tags=["Auth"])
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == body.email).first()
    if not user or not bcrypt.checkpw(body.password.encode(), user.password_hash.encode()):
        raise HTTPException(401, "Invalid email or password")
    return {"user_id": user.user_id, "name": user.name, "email": user.email, "token": _create_token(user.user_id)}


@app.get("/cabinet", tags=["Cabinet"])
def cabinet(
    current_user: models.User = Depends(_get_current_user),
    db: Session = Depends(get_db),
):
    records = (
        db.query(models.TamgaRecord)
        .filter(models.TamgaRecord.user_id == current_user.user_id)
        .order_by(models.TamgaRecord.created_at.desc())
        .limit(50)
        .all()
    )
    total = len(records)
    verified = sum(1 for r in records if r.status == "VERIFIED")
    return {
        "user": {"name": current_user.name, "email": current_user.email},
        "stats": {"total_scans": total, "verified": verified, "blocked": total - verified},
        "history": [
            {
                "tamga_id": r.tamga_id,
                "status": r.status or "UNKNOWN",
                "trust_score": r.trust_score,
                "timestamp": str(r.created_at),
            }
            for r in records
        ],
    }


@app.post("/verify-tamga", tags=["Tamga"])
async def verify_tamga(
    req: TamgaRequest,
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(_get_optional_user),
):
    t_start = time.monotonic()
    tamga_id = str(uuid.uuid4())
    hash_chain = build_hash_chain(req)

    # Try Go Aksakal core first, fall back to Python consensus
    aksakal = await _call_aksakal(req)
    consensus = tol_consensus(req)

    # If Aksakal responded — use its trust_score and status, keep Python's tol_sources
    if aksakal:
        consensus["trust_score"] = aksakal.get("trust_score", consensus["trust_score"])
        consensus["status"] = aksakal.get("status", consensus["status"])
        consensus["settlement"] = "SETTLED" if consensus["status"] == "VERIFIED" else "BLOCKED"
        consensus["message"] = "Funds Released" if consensus["status"] == "VERIFIED" else "Funds Frozen"
        consensus["aksakal_signature"] = list(aksakal.get("signature", []))
        consensus["aksakal_used"] = True
    else:
        consensus["aksakal_used"] = False

    proof = {
        "device_id": req.device_id,
        "gps": req.gps.model_dump(),
        "gyroscope": req.gyroscope.model_dump(),
        "wifi_mac": req.wifi_mac,
        "timestamp": req.timestamp,
        "document_hash": req.document_hash,
        "hash_chain": hash_chain,
    }

    record = models.TamgaRecord(
        tamga_id=tamga_id,
        device_id=req.device_id,
        gps=req.gps.model_dump(),
        gyroscope=req.gyroscope.model_dump(),
        wifi_mac=req.wifi_mac,
        timestamp=req.timestamp,
        document_hash=req.document_hash,
        hash_chain=hash_chain,
        trust_score=consensus["trust_score"],
        liveness_verified=str(consensus["liveness_verified"]),
        status=consensus["status"],
        user_id=current_user.user_id if current_user else None,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "tamga_id": tamga_id,
        "trust_score": consensus["trust_score"],
        "liveness_verified": consensus["liveness_verified"],
        "consensus_verified": consensus["consensus_verified"],
        "status": consensus["status"],
        "settlement": consensus["settlement"],
        "message": consensus["message"],
        "solana_tx": consensus["solana_tx"],
        "solana_explorer": consensus["solana_explorer"],
        "tol_sources": consensus["tol_sources"],
        "latency_ms": int((time.monotonic() - t_start) * 1000),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "evidence": consensus["evidence"],
        "hash_chain": hash_chain,
        "sparkplug_event": "DBIRTH",
        "aksakal_used": consensus.get("aksakal_used", False),
        "qumyrsqa_tamga_proof": proof,
    }


@app.get("/verify-tamga/{tamga_id}", tags=["Tamga"])
def get_tamga(tamga_id: str, db: Session = Depends(get_db)):
    record = db.query(models.TamgaRecord).filter(models.TamgaRecord.tamga_id == tamga_id).first()
    if not record:
        raise HTTPException(404, "Tamga record not found")
    return {
        "tamga_id": record.tamga_id,
        "device_id": record.device_id,
        "gps": record.gps,
        "gyroscope": record.gyroscope,
        "wifi_mac": record.wifi_mac,
        "timestamp": record.timestamp,
        "document_hash": record.document_hash,
        "hash_chain": record.hash_chain,
        "trust_score": record.trust_score,
        "liveness_verified": record.liveness_verified == "True",
        "status": record.status,
        "sparkplug_event": "DBIRTH",
        "created_at": str(record.created_at),
    }


@app.get("/tamga-list", tags=["Tamga"])
def list_tamga(limit: int = 20, db: Session = Depends(get_db)):
    records = db.query(models.TamgaRecord).order_by(models.TamgaRecord.created_at.desc()).limit(limit).all()
    return [
        {
            "tamga_id": r.tamga_id,
            "device_id": r.device_id,
            "trust_score": r.trust_score,
            "status": r.status,
            "liveness_verified": r.liveness_verified == "True",
            "created_at": str(r.created_at),
        }
        for r in records
    ]
