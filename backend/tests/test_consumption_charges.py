import pytest
from app.core.config import settings
from app.core.timezone import get_today_ist

@pytest.mark.asyncio
async def test_consumption_recording_and_charge_calculation(client):
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    student_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "rahul@hostel.edu", "password": "Student@123"},
    )
    student_headers = {"Authorization": f"Bearer {student_login.json()['access_token']}"}
    student_id = student_login.json().get("user_id", 3)
    # verify student id
    me = await client.get(f"{settings.API_V1_STR}/auth/me", headers=student_headers)
    student_id = me.json()["id"]

    today = str(get_today_ist())

    # 1. Admin marks Rahul consumed Breakfast (₹40) and Dinner (₹70), but NOT Lunch (₹80)
    b_rec = await client.post(
        f"{settings.API_V1_STR}/consumption/record",
        headers=admin_headers,
        json={"user_id": student_id, "date": today, "meal_type": "BREAKFAST", "consumed": True},
    )
    assert b_rec.status_code == 200
    assert b_rec.json()["price_snapshot"] == 40.0

    l_rec = await client.post(
        f"{settings.API_V1_STR}/consumption/record",
        headers=admin_headers,
        json={"user_id": student_id, "date": today, "meal_type": "LUNCH", "consumed": False},
    )
    assert l_rec.status_code == 200
    assert l_rec.json()["price_snapshot"] == 0.0

    d_rec = await client.post(
        f"{settings.API_V1_STR}/consumption/record",
        headers=admin_headers,
        json={"user_id": student_id, "date": today, "meal_type": "DINNER", "consumed": True},
    )
    assert d_rec.status_code == 200
    assert d_rec.json()["price_snapshot"] == 70.0

    # 2. Check student expense summary: total charge must be 40 + 0 + 70 = 110.0
    exp_res = await client.get(f"{settings.API_V1_STR}/consumption/student-expenses", headers=student_headers)
    assert exp_res.status_code == 200
    exp_data = exp_res.json()
    assert exp_data["total_charges"] == 110.0
    assert exp_data["total_consumed_count"] == 2

    # 3. Change prices in the system: make breakfast ₹60 and dinner ₹90
    await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": 60.0, "lunch": 90.0, "dinner": 90.0},
    )

    # 4. Check that previous consumption records DID NOT retroactively change!
    exp_after = await client.get(f"{settings.API_V1_STR}/consumption/student-expenses", headers=student_headers)
    assert exp_after.status_code == 200
    # Must STILL be 110.0!
    assert exp_after.json()["total_charges"] == 110.0
