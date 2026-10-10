from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Hostel(Base):
    __tablename__ = "hostels"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    code = Column(String(50), unique=True, index=True, nullable=False)
    address = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    users = relationship("User", back_populates="hostel", cascade="all, delete-orphan")
    menus = relationship("Menu", back_populates="hostel", cascade="all, delete-orphan")
    prices = relationship("MealPrice", back_populates="hostel", cascade="all, delete-orphan")
    bookings = relationship("MealBooking", back_populates="hostel", cascade="all, delete-orphan")
