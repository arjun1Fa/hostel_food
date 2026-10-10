import pytest
from datetime import timedelta
from app.core.config import settings
from app.core.timezone import get_today_ist

@pytest.mark.asyncio
async def test_menu_lifecycle_and_publication(client):
    # Login as admin
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    # Login as demo student
    student_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": "arjun@hostel.edu", "password": "Student@123"},
    )
    student_headers = {"Authorization": f"Bearer {student_login.json()['access_token']}"}

    future_date = str(get_today_ist() + timedelta(days=5))

    # 1. Admin creates a draft dinner menu
    create_res = await client.post(
        f"{settings.API_V1_STR}/menus/",
        headers=admin_headers,
        json={
            "date": future_date,
            "meal_type": "DINNER",
            "title": "Paneer Tikka Platter",
            "description": "Special chef dinner",
            "is_published": False,
            "dishes": [
                {"name": "Paneer Tikka", "category": "Starter", "is_vegetarian": True},
                {"name": "Butter Naan", "category": "Bread", "is_vegetarian": True},
            ],
        },
    )
    assert create_res.status_code == 201
    menu_id = create_res.json()["id"]

    # 2. Student checks daily menu for future_date -> draft should NOT be visible
    stud_view = await client.get(
        f"{settings.API_V1_STR}/menus/daily/{future_date}",
        headers=student_headers,
    )
    assert stud_view.status_code == 200
    assert stud_view.json()["dinner"] is None

    # 3. Admin checks daily menu -> draft dinner is visible
    admin_view = await client.get(
        f"{settings.API_V1_STR}/menus/daily/{future_date}",
        headers=admin_headers,
    )
    assert admin_view.status_code == 200
    assert admin_view.json()["dinner"] is not None
    assert admin_view.json()["dinner"]["title"] == "Paneer Tikka Platter"

    # 4. Admin publishes the menu
    pub_res = await client.patch(
        f"{settings.API_V1_STR}/menus/{menu_id}/publish?is_published=true",
        headers=admin_headers,
    )
    assert pub_res.status_code == 200
    assert pub_res.json()["is_published"] is True

    # 5. Student now sees published dinner
    stud_view_published = await client.get(
        f"{settings.API_V1_STR}/menus/daily/{future_date}",
        headers=student_headers,
    )
    assert stud_view_published.status_code == 200
    assert stud_view_published.json()["dinner"]["title"] == "Paneer Tikka Platter"
