from datetime import datetime, timezone
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.core.timezone import get_tomorrow_ist
from app.models.user import User
from app.models.enums import UserRole, NotificationType
from app.models.booking import MealBooking
from app.models.notification import Notification

logger = logging.getLogger(__name__)

async def _process_reminders(db: AsyncSession, is_final: bool = False) -> dict:
    tomorrow = get_tomorrow_ist()
    sent_count = 0
    skipped_count = 0

    # Fetch all active students
    stud_res = await db.execute(
        select(User).where(User.role == UserRole.STUDENT, User.is_active == True)
    )
    students = stud_res.scalars().all()

    # Fetch tomorrow's bookings
    book_res = await db.execute(
        select(MealBooking).where(MealBooking.date == tomorrow)
    )
    bookings_map = {b.user_id: b for b in book_res.scalars().all()}

    for s in students:
        booking = bookings_map.get(s.id)

        unbooked_meals = []
        if not booking:
            unbooked_meals = ["Breakfast", "Lunch", "Dinner"]
        else:
            if not booking.breakfast_booked:
                unbooked_meals.append("Breakfast")
            if not booking.lunch_booked:
                unbooked_meals.append("Lunch")
            if not booking.dinner_booked:
                unbooked_meals.append("Dinner")

        # If all 3 meals are booked, skip reminder
        if booking and len(unbooked_meals) == 0:
            skipped_count += 1
            continue

        if not booking:
            if is_final:
                title = "⚠️ Final Call: Tomorrow's Meals Cutoff at Midnight!"
                msg = (
                    f"Hey {s.full_name}, you haven't booked any meals for tomorrow ({tomorrow}). "
                    "The cutoff is strictly 12:00 AM IST. Book now to secure your portions!"
                )
            else:
                title = "🍽️ Reminder: Book Your Meals for Tomorrow"
                msg = (
                    f"Hi {s.full_name}, tomorrow's menu ({tomorrow}) is published! "
                    "Please select your breakfast, lunch, and dinner preferences before midnight."
                )
        else:
            missing_str = ", ".join(unbooked_meals)
            if is_final:
                title = f"⚠️ Final Call: Complete Tomorrow's Booking ({missing_str})"
                msg = (
                    f"Hey {s.full_name}, you have not selected {missing_str} for tomorrow ({tomorrow}). "
                    "Bookings lock at 12:00 AM IST."
                )
            else:
                title = f"🍽️ Reminder: Unselected Meals for Tomorrow ({missing_str})"
                msg = (
                    f"Hi {s.full_name}, just a heads-up that {missing_str} is unselected for tomorrow ({tomorrow}). "
                    "Please update your booking if you plan to eat."
                )

        notification = Notification(
            user_id=s.id,
            title=title,
            message=msg,
            type=NotificationType.REMINDER,
            is_read=False,
        )
        db.add(notification)
        sent_count += 1

    await db.commit()
    logger.info(f"Booking reminders completed: sent {sent_count}, skipped {skipped_count}")
    return {
        "sent_count": sent_count,
        "skipped_count": skipped_count,
        "target_date": str(tomorrow),
        "is_final": is_final,
    }

async def run_booking_reminders(db: AsyncSession | None = None, is_final: bool = False) -> dict:
    if db is not None:
        return await _process_reminders(db, is_final)
    else:
        async with AsyncSessionLocal() as session:
            return await _process_reminders(session, is_final)
