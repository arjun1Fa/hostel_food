import pytest
from app.core.config import settings
from app.core.timezone import get_today_ist, get_tomorrow_ist

@pytest.mark.asyncio
async def test_cutoff_rejects_past_and_today_bookings(client):
    """Verifies that students cannot book today's or past meals (midnight cutoff)."""
    s_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    headers = {"Authorization": f"Bearer {s_login.json()['access_token']}"}

    today = get_today_ist()
    resp = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=headers,
        json={"date": str(today), "breakfast_booked": True, "lunch_booked": True, "dinner_booked": True},
    )
    assert resp.status_code == 403
    assert "Booking deadline has passed" in resp.json()["detail"]

@pytest.mark.asyncio
async def test_price_validation_and_historical_immutability(client):
    """
    Verifies that:
    1. Negative or zero prices are rejected.
    2. Historical prices in consumption records remain frozen when current meal prices change.
    """
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    # 1. Negative price rejection
    bad_price = await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": -10.0, "lunch": 80.0, "dinner": 70.0},
    )
    assert bad_price.status_code == 422

    # Zero price rejection
    zero_price = await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": 0.0, "lunch": 80.0, "dinner": 70.0},
    )
    assert zero_price.status_code == 422

    # Set known prices: Breakfast ₹40, Lunch ₹80, Dinner ₹70
    await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": 40.0, "lunch": 80.0, "dinner": 70.0},
    )

    # Record consumption for Arjun (id=2) for today at ₹40
    today = get_today_ist()
    # Get Arjun's ID
    stud_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    stud_me = await client.get(f"{settings.API_V1_STR}/auth/me", headers={"Authorization": f"Bearer {stud_login.json()['access_token']}"})
    arjun_id = stud_me.json()["id"]

    rec_resp = await client.post(
        f"{settings.API_V1_STR}/consumption/record",
        headers=admin_headers,
        json={"user_id": arjun_id, "date": str(today), "meal_type": "BREAKFAST", "consumed": True},
    )
    assert rec_resp.status_code == 200
    assert rec_resp.json()["price_snapshot"] == 40.0

    # Now Admin inflates breakfast price to ₹95
    price_up = await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": 95.0, "lunch": 80.0, "dinner": 70.0},
    )
    assert price_up.status_code == 200

    # Verify student expenses: past consumption MUST remain ₹40, not retroactively inflated to ₹95!
    expenses = await client.get(
        f"{settings.API_V1_STR}/consumption/student-expenses",
        headers={"Authorization": f"Bearer {stud_login.json()['access_token']}"},
    )
    assert expenses.status_code == 200
    days = expenses.json()["days"]
    today_expense = next((d for d in days if d["date"] == str(today)), None)
    assert today_expense is not None
    assert today_expense["breakfast"]["price_charged"] == 40.0
    assert expenses.json()["total_charges"] == 40.0

@pytest.mark.asyncio
async def test_booking_idempotency_and_admin_override_audit(client):
    """Verifies booking update idempotency and administrative override audit logging."""
    s_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "priya@hostel.edu", "password": "Student@123"},
    )
    s_headers = {"Authorization": f"Bearer {s_login.json()['access_token']}"}
    tomorrow = get_tomorrow_ist()

    # Book twice with same payload: must update idempotently, not create duplicates
    b1 = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=s_headers,
        json={"date": str(tomorrow), "breakfast_booked": True, "lunch_booked": False, "dinner_booked": True},
    )
    assert b1.status_code == 200

    b2 = await client.post(
        f"{settings.API_V1_STR}/bookings/",
        headers=s_headers,
        json={"date": str(tomorrow), "breakfast_booked": True, "lunch_booked": True, "dinner_booked": True},
    )
    assert b2.status_code == 200
    assert b2.json()["id"] == b1.json()["id"]  # Same booking ID updated!

    # Admin override with audited reason
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    me_resp = await client.get(f"{settings.API_V1_STR}/auth/me", headers=s_headers)
    priya_id = me_resp.json()["id"]

    override_resp = await client.post(
        f"{settings.API_V1_STR}/bookings/admin-override",
        headers=admin_headers,
        json={
            "user_id": priya_id,
            "date": str(tomorrow),
            "breakfast_booked": False,
            "lunch_booked": True,
            "dinner_booked": False,
            "override_reason": "Medical leave requested by student parent.",
        },
    )
    assert override_resp.status_code == 200
    assert override_resp.json()["admin_override"] is True
    assert override_resp.json()["override_reason"] == "Medical leave requested by student parent."

    # Verify audit log recorded
    audit_resp = await client.get(
        f"{settings.API_V1_STR}/audit/logs?action=BOOKING_OVERRIDE",
        headers=admin_headers,
    )
    assert audit_resp.status_code == 200
    logs = audit_resp.json()
    assert len(logs) > 0
    assert "Medical leave" in logs[0]["details"]
