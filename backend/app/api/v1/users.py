from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.user import User
from app.models.enums import UserRole
from app.schemas.user import UserOut, UserUpdate
from app.api.deps import get_current_admin

router = APIRouter(prefix="/users", tags=["Student Management"])

@router.get("/", response_model=list[UserOut])
async def list_students(
    active_only: bool = False,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    query = select(User).where(User.hostel_id == admin.hostel_id, User.role == UserRole.STUDENT)
    if active_only:
        query = query.where(User.is_active == True)
    query = query.order_by(User.full_name)
    result = await db.execute(query)
    return result.scalars().all()

@router.get("/{user_id}", response_model=UserOut)
async def get_user_detail(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(User).where(User.id == user_id, User.hostel_id == admin.hostel_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user

@router.patch("/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    req: UserUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(User).where(User.id == user_id, User.hostel_id == admin.hostel_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    from app.models.audit import AuditLog
    changes = []
    if req.full_name is not None and req.full_name != user.full_name:
        changes.append(f"name: {user.full_name} -> {req.full_name}")
        user.full_name = req.full_name
    if req.room_number is not None and req.room_number != user.room_number:
        changes.append(f"room: {user.room_number} -> {req.room_number}")
        user.room_number = req.room_number
    if req.phone_number is not None and req.phone_number != user.phone_number:
        changes.append(f"phone: {user.phone_number} -> {req.phone_number}")
        user.phone_number = req.phone_number
    if req.is_active is not None and req.is_active != user.is_active:
        changes.append(f"is_active: {user.is_active} -> {req.is_active}")
        user.is_active = req.is_active

    if changes:
        audit = AuditLog(
            user_id=admin.id,
            action="USER_UPDATE",
            resource=f"user:{user.id}",
            details=f"Admin {admin.email} updated student {user.email}: {', '.join(changes)}",
        )
        db.add(audit)

    await db.commit()
    await db.refresh(user)
    return user

