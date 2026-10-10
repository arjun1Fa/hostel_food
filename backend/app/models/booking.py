from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class MealBooking(Base):
    __tablename__ = "meal_bookings"

    id = Column(Integer, primary_key=True, index=True)
    hostel_id = Column(Integer, ForeignKey("hostels.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    breakfast_booked = Column(Boolean, default=False, nullable=False)
    lunch_booked = Column(Boolean, default=False, nullable=False)
    dinner_booked = Column(Boolean, default=False, nullable=False)
    booked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    admin_override = Column(Boolean, default=False, nullable=False)
    override_reason = Column(String(255), nullable=True)

    __table_args__ = (
        UniqueConstraint("user_id", "date", name="uq_user_booking_date"),
    )

    hostel = relationship("Hostel", back_populates="bookings")
    user = relationship("User", back_populates="bookings")
    consumption_records = relationship("ConsumptionRecord", back_populates="booking", cascade="all, delete-orphan")
