from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Enum as SQLEnum, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.enums import MealType

class ConsumptionRecord(Base):
    __tablename__ = "consumption_records"

    id = Column(Integer, primary_key=True, index=True)
    hostel_id = Column(Integer, ForeignKey("hostels.id", ondelete="CASCADE"), nullable=False, index=True)
    booking_id = Column(Integer, ForeignKey("meal_bookings.id", ondelete="SET NULL"), nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    meal_type = Column(SQLEnum(MealType), nullable=False)
    consumed = Column(Boolean, default=False, nullable=False)
    price_snapshot = Column(Float, nullable=False, default=0.0)  # Price snapshot at recording
    recorded_by_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    correction_reason = Column(String(255), nullable=True)

    __table_args__ = (
        UniqueConstraint("user_id", "date", "meal_type", name="uq_user_date_meal_consumption"),
    )

    booking = relationship("MealBooking", back_populates="consumption_records")
    user = relationship("User", foreign_keys=[user_id], back_populates="consumption_records")
    recorded_by = relationship("User", foreign_keys=[recorded_by_user_id])
