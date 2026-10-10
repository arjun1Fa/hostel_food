import pytest
from app.core.config import settings

@pytest.mark.asyncio
async def test_admin_login_and_profile(client):
    res = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert "refresh_token" in data

    # Access protected profile
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    me_res = await client.get(f"{settings.API_V1_STR}/auth/me", headers=headers)
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["email"] == settings.ADMIN_EMAIL
    assert me_data["role"] == "ADMIN"

@pytest.mark.asyncio
async def test_student_registration_and_refresh_token_rotation(client):
    # Register student
    reg_res = await client.post(
        f"{settings.API_V1_STR}/auth/register",
        json={
            "email": "kavita@hostel.edu",
            "password": "Password123!",
            "full_name": "Kavita Singh",
            "room_number": "C-302",
            "phone_number": "+91 91234 56789",
        },
    )
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert reg_data["role"] == "STUDENT"

    # Login
    login_res = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "kavita@hostel.edu", "password": "Password123!"},
    )
    assert login_res.status_code == 200
    tokens = login_res.json()
    old_refresh = tokens["refresh_token"]

    # Rotate refresh token
    ref_res = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": old_refresh},
    )
    assert ref_res.status_code == 200
    new_tokens = ref_res.json()
    assert new_tokens["refresh_token"] != old_refresh

    # Try re-using old refresh token (must be rejected)
    reuse_res = await client.post(
        f"{settings.API_V1_STR}/auth/refresh",
        json={"refresh_token": old_refresh},
    )
    assert reuse_res.status_code == 401
