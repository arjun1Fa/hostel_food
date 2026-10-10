from datetime import datetime, date, timedelta
import pytz
from app.core.config import settings

def get_tz():
    return pytz.timezone(settings.TIMEZONE)

def get_now_ist() -> datetime:
    """Returns the authoritative current datetime in IST."""
    return datetime.now(get_tz())

def get_today_ist() -> date:
    """Returns today's calendar date in IST."""
    return get_now_ist().date()

def get_tomorrow_ist() -> date:
    """Returns tomorrow's calendar date in IST."""
    return get_today_ist() + timedelta(days=1)

def is_past_midnight_cutoff(target_date: date) -> bool:
    """
    Returns True if the midnight cutoff for target_date has passed.
    For target_date (e.g. tomorrow), students can book until 23:59:59 IST today.
    The moment now_ist.date() >= target_date, the cutoff has passed.
    """
    today = get_today_ist()
    return today >= target_date
