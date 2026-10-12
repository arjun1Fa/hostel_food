import time
from collections import defaultdict
from typing import Dict, List
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
from app.core.config import settings

class InMemoryRateLimiter:
    def __init__(self):
        # Maps (key, bucket) -> list of timestamp floats
        self._history: Dict[str, List[float]] = defaultdict(list)
        self.enabled = True

    def _clean_old_entries(self, key: str, window: int, current_time: float):
        cutoff = current_time - window
        self._history[key] = [t for t in self._history[key] if t > cutoff]

    def is_allowed(self, key: str, max_requests: int, window_seconds: int = 60) -> tuple[bool, int, int]:
        """
        Returns:
            allowed: bool
            remaining: int
            retry_after: int (seconds until next window opens)
        """
        if not self.enabled:
            return True, max_requests, 0

        now = time.time()
        self._clean_old_entries(key, window_seconds, now)
        current_count = len(self._history[key])

        if current_count >= max_requests:
            oldest = self._history[key][0]
            retry_after = max(1, int(window_seconds - (now - oldest)))
            return False, 0, retry_after

        self._history[key].append(now)
        remaining = max_requests - len(self._history[key])
        return True, remaining, 0

    def reset(self):
        """Reset all rate limiter state (useful for tests)"""
        self._history.clear()

limiter = InMemoryRateLimiter()

def get_client_ip(request: Request) -> str:
    # Handle X-Forwarded-For if behind trusted proxy
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "127.0.0.1"

class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        method = request.method
        ip = get_client_ip(request)

        # Define route limits
        max_req = settings.RATE_LIMIT_GENERAL_PER_MIN
        category = "general"

        if path.endswith("/auth/login") and method == "POST":
            max_req = settings.RATE_LIMIT_LOGIN_PER_MIN
            category = "login"
        elif path.endswith("/auth/register") and method == "POST":
            max_req = settings.RATE_LIMIT_REGISTER_PER_MIN
            category = "register"
        elif path.endswith("/auth/refresh") and method == "POST":
            max_req = settings.RATE_LIMIT_REFRESH_PER_MIN
            category = "refresh"

        key = f"{ip}:{category}"
        allowed, remaining, retry_after = limiter.is_allowed(key, max_req, window_seconds=60)

        if not allowed:
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={"detail": "Too many requests. Please slow down and try again later."},
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(max_req),
                    "X-RateLimit-Remaining": "0",
                },
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(max_req)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        return response
