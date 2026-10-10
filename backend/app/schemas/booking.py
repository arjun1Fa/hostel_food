from datetime import date, datetime
from pydantic import BaseModel, ConfigDict

class BookingCreate(BaseModel):
    date: date
    breakfast_booked: bool = False
    lunch_booked: bool = False
    dinner_booked: bool = False

class BookingAdminOverride(BaseModel):
    user_id: int
    date: date
    breakfast_booked: bool
    lunch_booked: bool
    dinner_booked: bool
    override_reason: str

class BookingOut(BaseModel):
    id: int
    user_id: int
    user_name: str | None = None
    room_number: str | None = None
    date: date
    breakfast_booked: bool
    lunch_booked: bool
    dinner_booked: bool
    booked_at: datetime
    updated_at: datetime
    admin_override: bool = False
    override_reason: str | None = None
    is_locked: bool = False
    estimated_cost: float = 0.0
    model_config = ConfigDict(from_attributes=True)

class DailyBookingSummary(BaseModel):
    date: date
    total_students: int
    breakfast_count: int
    lunch_count: int
    dinner_count: int
    students_booked: list[BookingOut] = []
