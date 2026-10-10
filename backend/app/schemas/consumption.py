from datetime import date, datetime
from pydantic import BaseModel, ConfigDict
from app.models.enums import MealType

class ConsumptionItemInput(BaseModel):
    user_id: int
    date: date
    meal_type: MealType
    consumed: bool
    correction_reason: str | None = None

class BatchConsumptionInput(BaseModel):
    items: list[ConsumptionItemInput]

class ConsumptionRecordOut(BaseModel):
    id: int
    user_id: int
    user_name: str | None = None
    room_number: str | None = None
    date: date
    meal_type: MealType
    consumed: bool
    price_snapshot: float
    recorded_by_name: str | None = None
    recorded_at: datetime
    correction_reason: str | None = None
    model_config = ConfigDict(from_attributes=True)

class StudentMealStatus(BaseModel):
    meal_type: MealType
    booked: bool = False
    consumed: bool = False
    price_charged: float = 0.0

class StudentDayExpenseOut(BaseModel):
    date: date
    breakfast: StudentMealStatus
    lunch: StudentMealStatus
    dinner: StudentMealStatus
    total_charge: float

class StudentExpenseSummaryOut(BaseModel):
    user_id: int
    user_name: str
    month: int
    year: int
    total_charges: float
    total_consumed_count: int
    days: list[StudentDayExpenseOut] = []
