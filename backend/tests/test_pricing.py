import pytest
from app.core.config import settings

@pytest.mark.asyncio
async def test_price_management_and_audit_history(client):
    admin_login = await client.post(
        f"{settings.API_V1_STR}/auth/login",
        json={"email": settings.ADMIN_EMAIL, "password": settings.ADMIN_PASSWORD},
    )
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    # Get initial prices
    p_get = await client.get(f"{settings.API_V1_STR}/prices/", headers=admin_headers)
    assert p_get.status_code == 200
    prices = p_get.json()
    assert prices["breakfast"] == 40.0
    assert prices["lunch"] == 80.0
    assert prices["dinner"] == 70.0

    # Update prices
    p_put = await client.put(
        f"{settings.API_V1_STR}/prices/",
        headers=admin_headers,
        json={"breakfast": 45.0, "lunch": 85.0, "dinner": 75.0},
    )
    assert p_put.status_code == 200
    assert p_put.json()["breakfast"] == 45.0
    assert p_put.json()["lunch"] == 85.0
    assert p_put.json()["dinner"] == 75.0

    # Check price history
    hist_res = await client.get(f"{settings.API_V1_STR}/prices/history", headers=admin_headers)
    assert hist_res.status_code == 200
    history = hist_res.json()
    assert len(history) >= 3
