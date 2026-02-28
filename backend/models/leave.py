from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timezone

class Leave(BaseModel):
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    leave_type: str  # "Full Day", "Half Day"
    half_day_type: Optional[str] = None  # "1st Half (Morning)", "2nd Half (Afternoon)"
    reason: str
    start_date: str
    end_date: Optional[str] = None
    voice_note_url: Optional[str] = None
    attachment_url: Optional[str] = None
    status: str = "pending"  # "pending", "approved", "rejected"
    admin_comment: Optional[str] = None
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class LeaveUpdate(BaseModel):
    status: Optional[str] = None
    admin_comment: Optional[str] = None
