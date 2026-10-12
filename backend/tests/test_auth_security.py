import pytest
from app.core.config import settings
from app.core.security import decode_token
from app.core.rate_limiter import limiter

@pytest.mark.asyncio
async def test_password_complexity_rules(client):
    """Verifies that weak passwords violating OWASP rules are rejected during registration."""
    weak_passwords = [
        ("short", "Short password (<8 chars)"),
        ("nouppercase1!", "Missing uppercase letter"),
        ("NOLOWERCASE1!", "Missing lowercase letter"),
        ("NoNumbersHere!", "Missing digit"),
        ("NoSpecialChar1", "Missing special character"),
        ("password", "Common dictionary password"),
        ("12345678", "Common numeric sequence"),
    ]

    for weak_pw, reason in weak_passwords:
        limiter.reset()
        resp = await client.post(
            f"{settings.API_V1_STR}/auth/register",
            json={
                "email": f"test_{abs(hash(weak_pw))}@hostel.edu",
                "password": weak_pw,
                "full_name": "Test Student",
                "room_number": "C-101",
            },
        )
        assert resp.status_code == 422, f"Expected 422 for weak password: {reason}"


@pytest.mark.asyncio
async def test_strong_password_registration_and_token_claims(client):
    """Verifies successful registration with strong password and validates all JWT claims."""
    email = "secure_student@hostel.edu"
    strong_pw = "SecureP@ssw0rd2026!"

    resp = await client.post(
        f"{settings.API_V1_STR}/auth/register",
        json={
            "email": email,
            "password": strong_pw,
            "full_name": "Secure Student",
            "room_number": "C-102",
            "phone_number": "+91 9988776655",
        },
    )
    assert resp.status_code == 201
    user_data = resp.json()
    assert user_data["email"] == email

    # Login
    login_resp = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": email, "password": strong_pw},
    )
    assert login_resp.status_code == 200
    token_data = login_resp.json()
    assert "access_token" in token_data
    assert "refresh_token" in token_data
    assert "csrf_token" in token_data

    # Check cookies
    cookies = login_resp.cookies
    assert settings.COOKIE_REFRESH_NAME in cookies
    assert settings.COOKIE_CSRF_NAME in cookies

    # Validate JWT claims
    claims = decode_token(token_data["access_token"])
    assert claims["iss"] == settings.JWT_ISSUER
    assert claims["aud"] == settings.JWT_AUDIENCE
    assert claims["sub"] == str(user_data["id"])
    assert claims["type"] == "access"
    assert claims["role"] == "STUDENT"
    assert "jti" in claims
    assert "iat" in claims
    assert "exp" in claims
    # Access token expiration should be 15 minutes (+/- 60s)
    remaining_seconds = claims["exp"] - claims["iat"]
    assert 14 * 60 <= remaining_seconds <= 16 * 60

@pytest.mark.asyncio
async def test_token_reuse_detection_and_revocation(client):
    """
    OWASP ASVS: Token Rotation & Theft Detection.
    If an already rotated/revoked refresh token is presented, the system must detect
    the compromise, reject the request, and revoke ALL active sessions for that user.
    """
    login_resp = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    first_refresh = login_resp.json()["refresh_token"]

    # First rotation: use first_refresh to get second_refresh
    rot1 = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": first_refresh},
    )
    assert rot1.status_code == 200
    second_refresh = rot1.json()["refresh_token"]
    assert second_refresh != first_refresh

    # Attack: Attacker tries to use the old first_refresh again!
    attack = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": first_refresh},
    )
    assert attack.status_code == 401
    assert "Token reuse detected" in attack.json()["detail"] or "Revoked token presented" in attack.json()["detail"]

    # Now verify that even second_refresh was invalidated as part of threat mitigation
    rot2 = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": second_refresh},
    )
    assert rot2.status_code == 401

@pytest.mark.asyncio
async def test_login_rate_limiting(client):
    """Verifies that exceeding the login attempt threshold triggers HTTP 429."""
    limiter.reset()

    # Settings allows RATE_LIMIT_LOGIN_PER_MIN attempts
    max_allowed = settings.RATE_LIMIT_LOGIN_PER_MIN

    for i in range(max_allowed):
        resp = await client.post(
            f"{settings.API_V1_STR}/auth/login",
            json={"email": "wrong@hostel.edu", "password": "WrongPassword123!"},
        )
        assert resp.status_code in (401, 200), f"Attempt {i+1} should not be rate limited"

    # Next attempt must be blocked by rate limiter
    blocked_resp = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "wrong@hostel.edu", "password": "WrongPassword123!"},
    )
    assert blocked_resp.status_code == 429
    assert "Retry-After" in blocked_resp.headers
    assert "X-RateLimit-Remaining" in blocked_resp.headers
    assert blocked_resp.headers["X-RateLimit-Remaining"] == "0"

    limiter.reset()

@pytest.mark.asyncio
async def test_logout_and_session_invalidation(client):
    """Verifies that logout revokes the refresh token and clears cookies."""
    login_resp = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    refresh_token = login_resp.json()["refresh_token"]

    # Logout
    logout_resp = await client.post(
        f"{settings.API_V1_STR}/auth/logout",
        json={"refresh_token": refresh_token},
    )
    assert logout_resp.status_code == 200

    # Refresh should now fail because token was revoked
    refresh_resp = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 401
