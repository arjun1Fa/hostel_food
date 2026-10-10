from datetime import date
from pydantic import BaseModel
from app.models.enums import MealType

class KitchenPrepItem(BaseModel):
    meal_type: MealType
    menu_title: str | None
    dish_names: list[str] = []
    total_portions: int
    published: bool

class KitchenPrepSheetOut(BaseModel):
    date: date
    hostel_name: str
    items: list[KitchenPrepItem]
    total_active_students: int
    total_bookings_day: int

class MealReportRow(BaseModel):
    date: date
    meal_type: MealType
    booked_count: int
    consumed_count: int
    unrecorded_count: int
    unit_price: float
    total_charge: float

class DailyReportOut(BaseModel):
    date: date
    breakfast: MealReportRow
    lunch: MealReportRow
    dinner: MealReportRow
    total_day_charges: float

class MonthlyReportOut(BaseModel):
    year: int
    month: int
    total_breakfast_consumed: int
    total_lunch_consumed: int
    total_dinner_consumed: int
    total_revenue_charges: float
    student_count: int
