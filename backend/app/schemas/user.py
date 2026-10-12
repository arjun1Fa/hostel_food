from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict, Field, field_validator
from app.models.enums import UserRole
from app.core.password_validator import validate_password_strength

class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    room_number: str | None = Field(default=None, max_length=20)
    phone_number: str | None = Field(default=None, max_length=20)

    @field_validator("full_name")
    @classmethod
    def sanitize_full_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Full name must be at least 2 characters")
        return v

class UserCreate(UserBase):
    password: str

    @field_validator("password")
    @classmethod
    def check_password_complexity(cls, v: str) -> str:
        return validate_password_strength(v)

class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=100)
    room_number: str | None = Field(default=None, max_length=20)
    phone_number: str | None = Field(default=None, max_length=20)
    is_active: bool | None = None

    @field_validator("full_name")
    @classmethod
    def sanitize_name(cls, v: str | None) -> str | None:
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError("Full name must be at least 2 characters")
        return v

class UserOut(UserBase):
    id: int
    hostel_id: int
    role: UserRole
    is_active: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

