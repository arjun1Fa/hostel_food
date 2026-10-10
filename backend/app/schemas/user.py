from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict
from app.models.enums import UserRole

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    room_number: str | None = None
    phone_number: str | None = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    full_name: str | None = None
    room_number: str | None = None
    phone_number: str | None = None
    is_active: bool | None = None

class UserOut(UserBase):
    id: int
    hostel_id: int
    role: UserRole
    is_active: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
