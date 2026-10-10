from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.menus import router as menus_router
from app.api.v1.prices import router as prices_router
from app.api.v1.bookings import router as bookings_router
from app.api.v1.consumption import router as consumption_router
from app.api.v1.reports import router as reports_router
from app.api.v1.notifications import router as notifications_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(menus_router)
api_router.include_router(prices_router)
api_router.include_router(bookings_router)
api_router.include_router(consumption_router)
api_router.include_router(reports_router)
api_router.include_router(notifications_router)
