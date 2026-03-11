from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Enum, Date
from sqlalchemy.sql import func
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date
import enum

from utils.mysql_db import Base

class LeaveType(str, enum.Enum):
    full_day = "Full Day"
    half_day = "Half Day"

class HalfDayType(str, enum.Enum):
    first_half = "1st Half (Morning)"
    second_half = "2nd Half (Afternoon)"

class LeaveStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"

class Leave(Base):
    __tablename__ = "leaves"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user_name = Column(String(255), nullable=False)
    user_email = Column(String(255), nullable=False)
    leave_type = Column(String(50), nullable=False)
    half_day_type = Column(String(50), nullable=True)
    reason = Column(Text, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    voice_note_url = Column(String(500), nullable=True)
    attachment_url = Column(String(500), nullable=True)
    status = Column(Enum(LeaveStatus), default=LeaveStatus.pending)
    admin_comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

# Pydantic models for API
class LeaveCreate(BaseModel):
    leave_type: str
    half_day_type: Optional[str] = None
    reason: str
    start_date: str
    end_date: Optional[str] = None
    voice_note_url: Optional[str] = None
    attachment_url: Optional[str] = None

class LeaveUpdate(BaseModel):
    status: Optional[str] = None
    admin_comment: Optional[str] = None

class LeaveResponse(BaseModel):
    id: int
    user_id: int
    user_name: str
    user_email: str
    leave_type: str
    half_day_type: Optional[str] = None
    reason: str
    start_date: str
    end_date: Optional[str] = None
    voice_note_url: Optional[str] = None
    attachment_url: Optional[str] = None
    status: str
    admin_comment: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
