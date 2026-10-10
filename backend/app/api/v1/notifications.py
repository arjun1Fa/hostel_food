from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.user import User
from app.models.notification import Notification, DeviceToken
from app.schemas.notification import NotificationOut, DeviceTokenCreate
from app.services.reminder_service import run_booking_reminders
from app.api.deps import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications & Reminders"])

@router.get("/", response_model=list[NotificationOut])
async def get_my_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = (
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    res = await db.execute(query)
    return res.scalars().all()

@router.patch("/{notification_id}/read", response_model=NotificationOut)
async def mark_notification_read(
    notification_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Notification).where(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    )
    res = await db.execute(query)
    n = res.scalar_one_or_none()
    if not n:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    n.is_read = True
    await db.commit()
    await db.refresh(n)
    return n

@router.post("/device-token")
async def register_device_token(
    req: DeviceTokenCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    res = await db.execute(select(DeviceToken).where(DeviceToken.token == req.token))
    existing = res.scalar_one_or_none()
    if existing:
        existing.user_id = current_user.id
        existing.platform = req.platform
    else:
        new_token = DeviceToken(
            user_id=current_user.id,
            token=req.token,
            platform=req.platform,
        )
        db.add(new_token)
    await db.commit()
    return {"message": "Device token registered"}

@router.post("/trigger-reminders")
async def trigger_reminders_test(
    is_final: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Developer and Admin test endpoint to trigger booking reminders on demand."""
    result = await run_booking_reminders(db=db, is_final=is_final)
    return result
