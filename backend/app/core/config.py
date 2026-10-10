import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    PROJECT_NAME: str = "Hostel Food Management"
    API_V1_STR: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = Field(
        default="sqlite+aiosqlite:///./hostel_food.db",
        description="Async SQLAlchemy database URL (SQLite or PostgreSQL)"
    )
    
    # JWT & Security
    SECRET_KEY: str = Field(
        default="hostel_super_secure_jwt_secret_key_antigravity_2026_change_in_prod",
        description="Secret key for JWT generation"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours for convenient dev/demo
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Timezone & Cutoff
    TIMEZONE: str = "Asia/Kolkata"
    
    # Reminder schedule (IST 24-hr format)
    REMINDER_FIRST_HOUR: int = 20  # 8:00 PM IST
    REMINDER_FIRST_MINUTE: int = 0
    REMINDER_FINAL_HOUR: int = 22  # 10:00 PM IST
    REMINDER_FINAL_MINUTE: int = 0
    
    # Default Single Hostel (Phase 1)
    DEFAULT_HOSTEL_NAME: str = "Heritage Boys & Girls Hostel"
    DEFAULT_HOSTEL_CODE: str = "HERITAGE-01"
    
    # Default initial admin bootstrap
    ADMIN_EMAIL: str = "admin@hostelfood.com"
    ADMIN_PASSWORD: str = "Admin@Hostel2026"
    ADMIN_NAME: str = "Hostel Administrator"
    
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

settings = Settings()
