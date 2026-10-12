from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.timezone import get_today_ist, get_tomorrow_ist, is_past_midnight_cutoff
from app.models.user import User
from app.models.enums import UserRole, MealType
from app.models.booking import MealBooking
from app.models.pricing import MealPrice
from app.models.audit import AuditLog
from app.schemas.booking import (
    BookingCreate,
    BookingAdminOverride,
    BookingOut,
    DailyBookingSummary,
)
from app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/bookings", tags=["Meal Bookings"])

async def _get_current_price_map(db: AsyncSession, hostel_id: int) -> dict[MealType, float]:
    res = await db.execute(select(MealPrice).where(MealPrice.hostel_id == hostel_id))
    prices = res.scalars().all()
    mapping = {MealType.BREAKFAST: 40.0, MealType.LUNCH: 80.0, MealType.DINNER: 70.0}
    for p in prices:
        mapping[p.meal_type] = p.price
    return mapping

def _calculate_estimated_cost(booking: MealBooking, price_map: dict[MealType, float]) -> float:
    total = 0.0
    if booking.breakfast_booked:
        total += price_map.get(MealType.BREAKFAST, 40.0)
    if booking.lunch_booked:
        total += price_map.get(MealType.LUNCH, 80.0)
    if booking.dinner_booked:
        total += price_map.get(MealType.DINNER, 70.0)
    return total

@router.get("/my", response_model=list[BookingOut])
async def get_my_bookings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = (
        select(MealBooking)
        .where(MealBooking.user_id == current_user.id)
        .order_by(MealBooking.date.desc())
        .limit(30)
    )
    res = await db.execute(query)
    bookings = res.scalars().all()
    price_map = await _get_current_price_map(db, current_user.hostel_id)

    out = []
    for b in bookings:
        locked = is_past_midnight_cutoff(b.date)
        cost = _calculate_estimated_cost(b, price_map)
        out.append(
            BookingOut(
                id=b.id,
                user_id=b.user_id,
                user_name=current_user.full_name,
                room_number=current_user.room_number,
                date=b.date,
                breakfast_booked=b.breakfast_booked,
                lunch_booked=b.lunch_booked,
                dinner_booked=b.dinner_booked,
                booked_at=b.booked_at,
                updated_at=b.updated_at,
                admin_override=b.admin_override,
                override_reason=b.override_reason,
                is_locked=locked,
                estimated_cost=cost,
            )
        )
    return out

@router.get("/for-date/{target_date}", response_model=BookingOut | None)
async def get_booking_for_date(
    target_date: date,
    user_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    target_user_id = current_user.id
    target_user = current_user

    if user_id is not None and user_id != current_user.id:
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Students cannot inspect bookings for other students.",
            )
        # Admin querying specific student: verify student belongs to same hostel
        user_res = await db.execute(
            select(User).where(User.id == user_id, User.hostel_id == current_user.hostel_id)
        )
        found_student = user_res.scalar_one_or_none()
        if not found_student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student not found in your hostel.",
            )
        target_user_id = user_id
        target_user = found_student

    query = select(MealBooking).where(
        MealBooking.user_id == target_user_id,
        MealBooking.date == target_date,
    )
    res = await db.execute(query)
    b = res.scalar_one_or_none()
    if not b:
        return None

    price_map = await _get_current_price_map(db, current_user.hostel_id)
    return BookingOut(
        id=b.id,
        user_id=b.user_id,
        user_name=target_user.full_name,
        room_number=target_user.room_number,
        date=b.date,
        breakfast_booked=b.breakfast_booked,
        lunch_booked=b.lunch_booked,
        dinner_booked=b.dinner_booked,
        booked_at=b.booked_at,
        updated_at=b.updated_at,
        admin_override=b.admin_override,
        override_reason=b.override_reason,
        is_locked=is_past_midnight_cutoff(b.date),
        estimated_cost=_calculate_estimated_cost(b, price_map),
    )

@router.post("/", response_model=BookingOut)
async def create_or_update_student_booking(
    req: BookingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Rule: Server-authoritative midnight cutoff check
    # Student can only book or modify if the cutoff for req.date has not passed.
    if is_past_midnight_cutoff(req.date):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Booking deadline has passed for {req.date}. Changes are locked after 12:00 AM IST.",
        )

    # Concurrency safe: check existing booking
    res = await db.execute(
        select(MealBooking).where(
            MealBooking.user_id == current_user.id,
            MealBooking.date == req.date,
        )
    )
    booking = res.scalar_one_or_none()

    now_utc = datetime.now(timezone.utc)
    from sqlalchemy.exc import IntegrityError

    if booking:
        booking.breakfast_booked = req.breakfast_booked
        booking.lunch_booked = req.lunch_booked
        booking.dinner_booked = req.dinner_booked
        booking.updated_at = now_utc
        await db.commit()
        await db.refresh(booking)
    else:
        booking = MealBooking(
            hostel_id=current_user.hostel_id,
            user_id=current_user.id,
            date=req.date,
            breakfast_booked=req.breakfast_booked,
            lunch_booked=req.lunch_booked,
            dinner_booked=req.dinner_booked,
            booked_at=now_utc,
            updated_at=now_utc,
            admin_override=False,
        )
        db.add(booking)
        try:
            await db.commit()
            await db.refresh(booking)
        except IntegrityError:
            await db.rollback()
            # Race condition resolved: update existing
            res2 = await db.execute(
                select(MealBooking).where(
                    MealBooking.user_id == current_user.id,
                    MealBooking.date == req.date,
                )
            )
            booking = res2.scalar_one()
            booking.breakfast_booked = req.breakfast_booked
            booking.lunch_booked = req.lunch_booked
            booking.dinner_booked = req.dinner_booked
            booking.updated_at = now_utc
            await db.commit()
            await db.refresh(booking)

    price_map = await _get_current_price_map(db, current_user.hostel_id)
    return BookingOut(
        id=booking.id,
        user_id=booking.user_id,
        user_name=current_user.full_name,
        room_number=current_user.room_number,
        date=booking.date,
        breakfast_booked=booking.breakfast_booked,
        lunch_booked=booking.lunch_booked,
        dinner_booked=booking.dinner_booked,
        booked_at=booking.booked_at,
        updated_at=booking.updated_at,
        admin_override=booking.admin_override,
        override_reason=booking.override_reason,
        is_locked=is_past_midnight_cutoff(booking.date),
        estimated_cost=_calculate_estimated_cost(booking, price_map),
    )


@router.post("/admin-override", response_model=BookingOut)
async def admin_override_booking(
    req: BookingAdminOverride,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    if not req.override_reason or not req.override_reason.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Override reason is required for administrative booking modifications.",
        )

    # Check student
    user_res = await db.execute(select(User).where(User.id == req.user_id, User.hostel_id == admin.hostel_id))
    student = user_res.scalar_one_or_none()
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found in this hostel")

    res = await db.execute(
        select(MealBooking).where(
            MealBooking.user_id == req.user_id,
            MealBooking.date == req.date,
        )
    )
    booking = res.scalar_one_or_none()

    now_utc = datetime.now(timezone.utc)
    if booking:
        booking.breakfast_booked = req.breakfast_booked
        booking.lunch_booked = req.lunch_booked
        booking.dinner_booked = req.dinner_booked
        booking.updated_at = now_utc
        booking.admin_override = True
        booking.override_reason = req.override_reason
    else:
        booking = MealBooking(
            hostel_id=admin.hostel_id,
            user_id=req.user_id,
            date=req.date,
            breakfast_booked=req.breakfast_booked,
            lunch_booked=req.lunch_booked,
            dinner_booked=req.dinner_booked,
            booked_at=now_utc,
            updated_at=now_utc,
            admin_override=True,
            override_reason=req.override_reason,
        )
        db.add(booking)

    # Log to AuditLog
    audit = AuditLog(
        user_id=admin.id,
        action="BOOKING_OVERRIDE",
        resource=f"user:{req.user_id}, date:{req.date}",
        details=f"Overridden by {admin.full_name}. Reason: {req.override_reason}. B:{req.breakfast_booked}, L:{req.lunch_booked}, D:{req.dinner_booked}",
        created_at=now_utc,
    )
    db.add(audit)

    await db.commit()
    await db.refresh(booking)

    price_map = await _get_current_price_map(db, admin.hostel_id)
    return BookingOut(
        id=booking.id,
        user_id=booking.user_id,
        user_name=student.full_name,
        room_number=student.room_number,
        date=booking.date,
        breakfast_booked=booking.breakfast_booked,
        lunch_booked=booking.lunch_booked,
        dinner_booked=booking.dinner_booked,
        booked_at=booking.booked_at,
        updated_at=booking.updated_at,
        admin_override=booking.admin_override,
        override_reason=booking.override_reason,
        is_locked=is_past_midnight_cutoff(booking.date),
        estimated_cost=_calculate_estimated_cost(booking, price_map),
    )

@router.get("/admin/summary/{target_date}", response_model=DailyBookingSummary)
async def get_admin_booking_summary(
    target_date: date,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    # Total active students
    total_stud_res = await db.execute(
        select(User).where(User.hostel_id == admin.hostel_id, User.role == UserRole.STUDENT, User.is_active == True)
    )
    students = total_stud_res.scalars().all()
    students_map = {s.id: s for s in students}

    bookings_res = await db.execute(
        select(MealBooking).where(MealBooking.hostel_id == admin.hostel_id, MealBooking.date == target_date)
    )
    bookings = bookings_res.scalars().all()

    price_map = await _get_current_price_map(db, admin.hostel_id)

    b_count = 0
    l_count = 0
    d_count = 0
    booked_list = []

    for b in bookings:
        if b.breakfast_booked:
            b_count += 1
        if b.lunch_booked:
            l_count += 1
        if b.dinner_booked:
            d_count += 1
        
        user_info = students_map.get(b.user_id)
        booked_list.append(
            BookingOut(
                id=b.id,
                user_id=b.user_id,
                user_name=user_info.full_name if user_info else f"Student #{b.user_id}",
                room_number=user_info.room_number if user_info else None,
                date=b.date,
                breakfast_booked=b.breakfast_booked,
                lunch_booked=b.lunch_booked,
                dinner_booked=b.dinner_booked,
                booked_at=b.booked_at,
                updated_at=b.updated_at,
                admin_override=b.admin_override,
                override_reason=b.override_reason,
                is_locked=is_past_midnight_cutoff(b.date),
                estimated_cost=_calculate_estimated_cost(b, price_map),
            )
        )

    return DailyBookingSummary(
        date=target_date,
        total_students=len(students),
        breakfast_count=b_count,
        lunch_count=l_count,
        dinner_count=d_count,
        students_booked=booked_list,
    )
