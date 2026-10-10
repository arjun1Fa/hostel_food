from datetime import date, datetime
from pydantic import BaseModel, ConfigDict
from app.models.enums import MealType

class DishBase(BaseModel):
    name: str
    category: str | None = None
    is_vegetarian: bool = True

class DishCreate(DishBase):
    pass

class DishOut(DishBase):
    id: int
    menu_id: int
    model_config = ConfigDict(from_attributes=True)

class MenuBase(BaseModel):
    date: date
    meal_type: MealType
    title: str
    description: str | None = None
    image_url: str | None = None
    dietary_tags: str | None = ""
    is_published: bool = False

class MenuCreate(MenuBase):
    dishes: list[DishCreate] = []

class MenuUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    image_url: str | None = None
    dietary_tags: str | None = None
    is_published: bool | None = None
    dishes: list[DishCreate] | None = None

class MenuOut(MenuBase):
    id: int
    hostel_id: int
    dishes: list[DishOut] = []
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

class DayMealsOut(BaseModel):
    date: date
    breakfast: MenuOut | None = None
    lunch: MenuOut | None = None
    dinner: MenuOut | None = None
