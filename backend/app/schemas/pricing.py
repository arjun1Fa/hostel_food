from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
from app.models.enums import MealType

class MealPriceUpdate(BaseModel):
    meal_type: MealType
    price: float = Field(gt=0.0, le=10000.0)

class AllPricesUpdate(BaseModel):
    breakfast: float = Field(gt=0.0, le=10000.0)
    lunch: float = Field(gt=0.0, le=10000.0)
    dinner: float = Field(gt=0.0, le=10000.0)


class MealPricesOut(BaseModel):
    breakfast: float
    lunch: float
    dinner: float
    effective_from: datetime | None = None

class PriceHistoryOut(BaseModel):
    id: int
    meal_type: MealType
    old_price: float
    new_price: float
    changed_by_name: str | None = None
    changed_at: datetime
    model_config = ConfigDict(from_attributes=True)
