import pytest
from app.core.config import settings
from app.core.timezone import get_tomorrow_ist

@pytest.mark.asyncio
async def test_student_cannot_inspect_other_student_bookings(client):
    """IDOR test: Student A attempts to query Student B's booking by passing target user_id."""
    # Student 1: Arjun Sharma (id 2 or fetched via /auth/me)
    s1_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    s1_token = s1_login.json()["access_token"]
    s1_headers = {"Authorization": f"Bearer {s1_token}"}

    # Student 2: Priya Patel
    s2_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "priya@hostel.edu", "password": "Student@123"},
    )
    s2_id = s2_login.json()["access_token"]
    # Get Priya's user ID
    s2_me = await client.get(f"{settings.API_V1_STR}/auth/me", headers={"Authorization": f"Bearer {s2_id}"})
    priya_id = s2_me.json()["id"]

    tomorrow = get_tomorrow_ist()

    # Arjun tries to inspect Priya's booking for tomorrow
    idor_attempt = await client.get(
        f"{settings.API_V1_STR}/bookings/for-date/{tomorrow}?user_id={priya_id}",
        headers=s1_headers,
    )
    assert idor_attempt.status_code == 403
    assert "Access denied" in idor_attempt.json()["detail"]

@pytest.mark.asyncio
async def test_student_cannot_inspect_other_student_expenses(client):
    """IDOR test: Student A attempts to query Student B's expenses via target_user_id."""
    s1_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    s1_headers = {"Authorization": f"Bearer {s1_login.json()['access_token']}"}

    # Querying someone else's expenses
    idor_resp = await client.get(
        f"{settings.API_V1_STR}/consumption/student-expenses?target_user_id=999",
        headers=s1_headers,
    )
    assert idor_resp.status_code == 403
    assert "Access denied" in idor_resp.json()["detail"]

@pytest.mark.asyncio
async def test_role_based_access_control_admin_endpoints(client):
    """Verifies that non-admin accounts cannot access protected administrative endpoints."""
    student_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    headers = {"Authorization": f"Bearer {student_login.json()['access_token']}"}
    tomorrow = get_tomorrow_ist()

    # 1. Price update
    res1 = await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=headers,
        json={"breakfast": 50.0, "lunch": 100.0, "dinner": 90.0},
    )
    assert res1.status_code == 403

    # 2. Reports
    res2 = await client.get(
        f"{settings.API_V1_STR}/reports/kitchen-prep/{tomorrow}",
        headers=headers,
    )
    assert res2.status_code == 403

    # 3. Consumption recording
    res3 = await client.post(
        f"{settings.API_V1_STR}/consumption/record",
        headers=headers,
        json={"user_id": 1, "date": str(tomorrow), "meal_type": "BREAKFAST", "consumed": True},
    )
    assert res3.status_code == 403

    # 4. User management
    res4 = await client.get(f"{settings.API_V1_STR}/users/", headers=headers)
    assert res4.status_code == 403

    # 5. Reminder trigger
    res5 = await client.post(f"{settings.API_V1_STR}/notifications/trigger-reminders", headers=headers)
    assert res5.status_code == 403

    # 6. Audit logs
    res6 = await client.get(f"{settings.API_V1_STR}/audit/logs", headers=headers)
    assert res6.status_code == 403
