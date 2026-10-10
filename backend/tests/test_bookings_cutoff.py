import pytest
from datetime import timedelta
from app.core.config import settings
from app.core.timezone import get_today_ist, get_tomorrow_ist

@pytest.mark.asyncio
async def test_booking_workflow_and_midnight_cutoff(client):
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    student_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "priya@hostel.edu", "password": "Student@123"},
    )
    student_headers = {"Authorization": f"Bearer {student_login.json()['access_token']}"}

    today = get_today_ist()
    tomorrow = get_tomorrow_ist()

    # 1. Student books tomorrow's meals (Breakfast + Dinner, skipping Lunch)
    book_res = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=student_headers,
        json={
            "date": str(tomorrow),
            "breakfast_booked": True,
            "lunch_booked": False,
            "dinner_booked": True,
        },
    )
    assert book_res.status_code == 200
    b_data = book_res.json()
    assert b_data["breakfast_booked"] is True
    assert b_data["lunch_booked"] is False
    assert b_data["dinner_booked"] is True
    # 40 (breakfast) + 70 (dinner) = 110.0
    assert b_data["estimated_cost"] == 110.0
    assert b_data["is_locked"] is False

    # 2. Student modifies tomorrow's booking before deadline
    modify_res = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=student_headers,
        json={
            "date": str(tomorrow),
            "breakfast_booked": True,
            "lunch_booked": True,
            "dinner_booked": True,
        },
    )
    assert modify_res.status_code == 200
    m_data = modify_res.json()
    assert m_data["lunch_booked"] is True
    # 40 + 80 + 70 = 190.0
    assert m_data["estimated_cost"] == 190.0

    # 3. Student tries to modify TODAY's meals -> past midnight cutoff -> MUST FAIL with 403
    today_res = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=student_headers,
        json={
            "date": str(today),
            "breakfast_booked": True,
            "lunch_booked": True,
            "dinner_booked": True,
        },
    )
    assert today_res.status_code == 403
    assert "locked after 12:00 AM IST" in today_res.json()["detail"]

    # 4. Student tries to modify a past date -> MUST FAIL with 403
    past_date = str(today - timedelta(days=2))
    past_res = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=student_headers,
        json={
            "date": past_date,
            "breakfast_booked": True,
            "lunch_booked": False,
            "dinner_booked": False,
        },
    )
    assert past_res.status_code == 403

    # 5. Admin can override past or locked date with reason
    user_me = await client.get(f"{settings.API_V1_STR}/auth/me", headers=student_headers)
    student_id = user_me.json()["id"]

    override_res = await client.post(
        f"{settings.API_V1_STR}/bookings/admin-override",
        headers=admin_headers,
        json={
            "user_id": student_id,
            "date": str(today),
            "breakfast_booked": True,
            "lunch_booked": True,
            "dinner_booked": False,
            "override_reason": "Late arrival authorized by warden",
        },
    )
    assert override_res.status_code == 200
    ov_data = override_res.json()
    assert ov_data["admin_override"] is True
    assert ov_data["override_reason"] == "Late arrival authorized by warden"
