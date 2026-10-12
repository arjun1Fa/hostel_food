import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from app.core.config import settings

logger = logging.getLogger("hostel_food")

def setup_exception_handlers(app: FastAPI):
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled exception on {request.method} {request.url.path}: {exc}", exc_info=True)
        if settings.ENVIRONMENT == "production":
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={"detail": "An internal server error occurred. Please contact the system administrator."},
            )
        # In non-production, return message without full internal trace stack
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": str(exc)},
        )
