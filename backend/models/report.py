from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, field_schema):
        field_schema.update(type="string")

class ReportBase(BaseModel):
    title: str
    description: str
    priority: str = "medium"
    category: str = "general"

class ReportCreate(ReportBase):
    attachments: Optional[List[str]] = []
    voice_notes: Optional[List[str]] = []

class ReportUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    category: Optional[str] = None

class ReportResponse(ReportBase):
    id: str = Field(alias="_id")
    user_id: str
    user_name: str
    status: str = "pending"
    attachments: List[str] = []
    voice_notes: List[str] = []
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}

class ReportInDB(ReportBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    user_id: str
    user_name: str
    status: str = "pending"
    attachments: List[str] = []
    voice_notes: List[str] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
