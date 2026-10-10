import pytest
from app.core.config import settings
from app.core.timezone import get_tomorrow_ist, get_today_ist

@pytest.mark.asyncio
async def test_kitchen_prep_sheet_and_reports(client):
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    tomorrow = str(get_tomorrow_ist())

    # Fetch kitchen prep sheet
    prep_res = await client.get(f"{settings.API_V1_STR}/reports/kitchen-prep/{tomorrow}", headers=admin_headers)
    assert prep_res.status_code == 200
    sheet = prep_res.json()
    assert sheet["hostel_name"] == settings.DEFAULT_HOSTEL_NAME
    assert len(sheet["items"]) == 3  # Breakfast, Lunch, Dinner

    # Test CSV export
    csv_res = await client.get(f"{settings.API_V1_STR}/reports/export-csv?target_date={tomorrow}&report_type=kitchen_prep", headers=admin_headers)
    assert csv_res.status_code == 200
    assert "Kitchen Preparation Sheet" in csv_res.text

@pytest.mark.asyncio
async def test_reminder_trigger_test_mode(client):
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    rem_res = await client.post(
        f"{settings.API_V1_STR}/notifications/trigger-reminders?is_final=false",
        headers=admin_headers,
    )
    assert rem_res.status_code == 200
    res_data = rem_res.json()
    assert "sent_count" in res_data
    assert res_data["sent_count"] > 0
