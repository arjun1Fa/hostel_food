from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Boolean, Date, DateTime, ForeignKey, Enum as SQLEnum, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.enums import MealType

class Menu(Base):
    __tablename__ = "menus"

    id = Column(Integer, primary_key=True, index=True)
    hostel_id = Column(Integer, ForeignKey("hostels.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    meal_type = Column(SQLEnum(MealType), nullable=False)
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(String(255), nullable=True)
    dietary_tags = Column(String(255), nullable=True, default="")  # comma separated or json
    is_published = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("hostel_id", "date", "meal_type", name="uq_menu_hostel_date_meal"),
    )

    hostel = relationship("Hostel", back_populates="menus")
    dishes = relationship("MenuDish", back_populates="menu", cascade="all, delete-orphan", order_by="MenuDish.id")


class MenuDish(Base):
    __tablename__ = "menu_dishes"

    id = Column(Integer, primary_key=True, index=True)
    menu_id = Column(Integer, ForeignKey("menus.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    category = Column(String(100), nullable=True)  # e.g., "Main Course", "Side", "Beverage"
    is_vegetarian = Column(Boolean, default=True, nullable=False)

    menu = relationship("Menu", back_populates="dishes")
