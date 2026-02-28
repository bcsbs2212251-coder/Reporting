from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timezone

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetVerify(BaseModel):
    email: EmailStr
    reset_token: str
    new_password: str

class PasswordResetToken(BaseModel):
    email: str
    token: str
    expires_at: str
    created_at: str = None
    
    def __init__(self, **data):
        if 'created_at' not in data:
            data['created_at'] = datetime.now(timezone.utc).isoformat()
        super().__init__(**data)