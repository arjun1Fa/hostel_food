import pytest
from app.core.config import settings

@pytest.mark.asyncio
async def test_security_headers_present(client):
    """Verifies that all API responses include standard OWASP security headers."""
    resp = await client.get("/health")
    assert resp.status_code == 200

    headers = resp.headers
    assert headers.get("x-content-type-options") == "nosniff"
    assert headers.get("x-frame-options") == "DENY"
    assert headers.get("x-xss-protection") == "1; mode=block"
    assert headers.get("referrer-policy") == "strict-origin-when-cross-origin"
    assert "Content-Security-Policy" in headers or "content-security-policy" in headers
    assert "permissions-policy" in headers

@pytest.mark.asyncio
async def test_oversized_payload_rejected(client):
    """Verifies that payloads exceeding maximum allowed size are rejected with HTTP 413."""
    oversized_length = str(settings.MAX_REQUEST_BODY_SIZE_BYTES + 1024)
    resp = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        headers={"Content-Length": oversized_length},
        content=b"dummy",
    )
    assert resp.status_code == 413
    assert "Request payload too large" in resp.json()["detail"]

@pytest.mark.asyncio
async def test_cors_behavior(client):
    """Verifies CORS headers for allowed origins."""
    origin = "http://localhost:3000"
    resp = await client.options(
        f"{settings.API_V1_STR}/menus/",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.headers.get("access-control-allow-origin") == origin
    assert resp.headers.get("access-control-allow-credentials") == "true"
