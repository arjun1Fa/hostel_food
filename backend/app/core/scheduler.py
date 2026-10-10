import logging
import pytz
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.core.config import settings
from app.services.reminder_service import run_booking_reminders

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler(timezone=pytz.timezone(settings.TIMEZONE))

def start_scheduler():
    try:
        # 8:00 PM IST First Reminder
        scheduler.add_job(
            run_booking_reminders,
            CronTrigger(
                hour=settings.REMINDER_FIRST_HOUR,
                minute=settings.REMINDER_FIRST_MINUTE,
                timezone=pytz.timezone(settings.TIMEZONE)
            ),
            id="reminder_8pm",
            replace_existing=True,
            args=[False],
        )

        # 10:00 PM IST Final Reminder
        scheduler.add_job(
            run_booking_reminders,
            CronTrigger(
                hour=settings.REMINDER_FINAL_HOUR,
                minute=settings.REMINDER_FINAL_MINUTE,
                timezone=pytz.timezone(settings.TIMEZONE)
            ),
            id="reminder_10pm",
            replace_existing=True,
            args=[True],
        )

        scheduler.start()
        logger.info("APScheduler started successfully with 8 PM and 10 PM IST reminder jobs.")
    except Exception as e:
        logger.error(f"Error starting scheduler: {e}")

def stop_scheduler():
    if scheduler.running:
        scheduler.shutdown()
