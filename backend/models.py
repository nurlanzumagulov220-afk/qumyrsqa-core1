from sqlalchemy import Column, String, Float, JSON, DateTime
from sqlalchemy.sql import func
from database import Base


class User(Base):
    __tablename__ = "users"

    user_id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class TamgaRecord(Base):
    __tablename__ = "tamga_records"

    tamga_id = Column(String, primary_key=True, index=True)
    device_id = Column(String, nullable=False)
    gps = Column(JSON, nullable=False)
    gyroscope = Column(JSON, nullable=False)
    wifi_mac = Column(JSON, nullable=False)
    timestamp = Column(String, nullable=False)
    document_hash = Column(String, nullable=False)
    hash_chain = Column(String, nullable=False)
    trust_score = Column(Float, nullable=False)
    liveness_verified = Column(String, nullable=False)
    status = Column(String, nullable=True)
    user_id = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
