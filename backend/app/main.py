from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.scheduler import start_scheduler, stop_scheduler
from app.bootstrap import bootstrap_app
from app.api.v1 import api_router
import app.models  # ensure all models are registered

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Bootstrap default hostel, admin, prices, and demo data
    async with AsyncSessionLocal() as session:
        await bootstrap_app(session)

    # Start APScheduler for reminders
    start_scheduler()

    yield

    stop_scheduler()

from app.core.security_headers import SecurityHeadersMiddleware
from app.core.rate_limiter import RateLimitMiddleware
from app.core.error_handler import setup_exception_handlers

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# Exception handlers for sanitized error disclosure
setup_exception_handlers(app)

# Security headers & payload size limit
app.add_middleware(SecurityHeadersMiddleware)

# Rate limiting for auth and abuse prevention
app.add_middleware(RateLimitMiddleware)

# Strict CORS configuration supporting credentials (cookies) for Web and PWA
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-RateLimit-Limit", "X-RateLimit-Remaining", "Retry-After", "Content-Disposition"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "timezone": settings.TIMEZONE,
    }
