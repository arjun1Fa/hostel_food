import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    PROJECT_NAME: str = "Hostel Food Management"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    
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
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15  # Short-lived access token (OWASP compliance)
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    JWT_ISSUER: str = "hostel-dining-api"
    JWT_AUDIENCE: str = "hostel-dining-client"
    
    # CORS: Allowed origins for Web / PWA
    CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
    ]
    
    # Cookie Configuration for Web / PWA
    COOKIE_SECURE: bool = False  # Set to True when HTTPS is enabled
    COOKIE_SAMESITE: str = "lax"
    COOKIE_REFRESH_NAME: str = "hostel_refresh_token"
    COOKIE_CSRF_NAME: str = "hostel_csrf_token"
    
    # Rate Limiting
    RATE_LIMIT_LOGIN_PER_MIN: int = 5
    RATE_LIMIT_REGISTER_PER_MIN: int = 5
    RATE_LIMIT_REFRESH_PER_MIN: int = 30
    RATE_LIMIT_GENERAL_PER_MIN: int = 180
    
    # Request limits
    MAX_REQUEST_BODY_SIZE_BYTES: int = 10 * 1024 * 1024  # 10 MB
    
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
    
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True, extra="ignore")

settings = Settings()

