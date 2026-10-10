from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, extract
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.user import User
from app.models.enums import UserRole, MealType
from app.models.booking import MealBooking
from app.models.consumption import ConsumptionRecord
from app.models.pricing import MealPrice
from app.models.audit import AuditLog
from app.schemas.consumption import (
    ConsumptionItemInput,
    BatchConsumptionInput,
    ConsumptionRecordOut,
    StudentMealStatus,
    StudentDayExpenseOut,
    StudentExpenseSummaryOut,
)
from app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/consumption", tags=["Meal Consumption & Charges"])

async def _get_applicable_price(db: AsyncSession, hostel_id: int, meal_type: MealType) -> float:
    res = await db.execute(
        select(MealPrice).where(MealPrice.hostel_id == hostel_id, MealPrice.meal_type == meal_type)
    )
    p = res.scalar_one_or_none()
    if p:
        return p.price
    defaults = {MealType.BREAKFAST: 40.0, MealType.LUNCH: 80.0, MealType.DINNER: 70.0}
    return defaults.get(meal_type, 50.0)

@router.post("/record", response_model=ConsumptionRecordOut)
async def record_consumption(
    req: ConsumptionItemInput,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    # Verify student
    user_res = await db.execute(select(User).where(User.id == req.user_id, User.hostel_id == admin.hostel_id))
    student = user_res.scalar_one_or_none()
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    # Fetch booking if exists
    b_res = await db.execute(
        select(MealBooking).where(MealBooking.user_id == req.user_id, MealBooking.date == req.date)
    )
    booking = b_res.scalar_one_or_none()

    # Check existing consumption record
    c_res = await db.execute(
        select(ConsumptionRecord).where(
            ConsumptionRecord.user_id == req.user_id,
            ConsumptionRecord.date == req.date,
            ConsumptionRecord.meal_type == req.meal_type,
        )
    )
    record = c_res.scalar_one_or_none()

    now_utc = datetime.now(timezone.utc)

    if record:
        # Correction of existing record
        old_status = record.consumed
        record.consumed = req.consumed
        record.correction_reason = req.correction_reason
        record.recorded_by_user_id = admin.id
        record.recorded_at = now_utc
        # If toggled to consumed and snapshot was 0, capture snapshot
        if req.consumed and record.price_snapshot == 0.0:
            record.price_snapshot = await _get_applicable_price(db, admin.hostel_id, req.meal_type)
        elif not req.consumed:
            # If not consumed, charge is 0
            record.price_snapshot = 0.0

        audit = AuditLog(
            user_id=admin.id,
            action="CONSUMPTION_CORRECTION",
            resource=f"user:{req.user_id}, date:{req.date}, meal:{req.meal_type.value}",
            details=f"Status changed from {old_status} to {req.consumed}. Reason: {req.correction_reason}",
            created_at=now_utc,
        )
        db.add(audit)
    else:
        # New record: snapshot price if consumed
        price_snapshot = await _get_applicable_price(db, admin.hostel_id, req.meal_type) if req.consumed else 0.0
        record = ConsumptionRecord(
            hostel_id=admin.hostel_id,
            booking_id=booking.id if booking else None,
            user_id=req.user_id,
            date=req.date,
            meal_type=req.meal_type,
            consumed=req.consumed,
            price_snapshot=price_snapshot,
            recorded_by_user_id=admin.id,
            recorded_at=now_utc,
            correction_reason=req.correction_reason,
        )
        db.add(record)

    await db.commit()
    await db.refresh(record)

    return ConsumptionRecordOut(
        id=record.id,
        user_id=record.user_id,
        user_name=student.full_name,
        room_number=student.room_number,
        date=record.date,
        meal_type=record.meal_type,
        consumed=record.consumed,
        price_snapshot=record.price_snapshot,
        recorded_by_name=admin.full_name,
        recorded_at=record.recorded_at,
        correction_reason=record.correction_reason,
    )

@router.post("/batch-record", response_model=list[ConsumptionRecordOut])
async def batch_record_consumption(
    req: BatchConsumptionInput,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    results = []
    for item in req.items:
        rec = await record_consumption(item, db, admin)
        results.append(rec)
    return results

@router.get("/summary/{target_date}")
async def get_consumption_summary_for_date(
    target_date: date,
    meal_type: MealType | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Returns all registered students with their booking status, consumption status,
    and applicable price for the date.
    """
    students_res = await db.execute(
        select(User).where(User.hostel_id == admin.hostel_id, User.role == UserRole.STUDENT, User.is_active == True)
        .order_by(User.room_number, User.full_name)
    )
    students = students_res.scalars().all()

    # Get bookings for this date
    bookings_res = await db.execute(
        select(MealBooking).where(MealBooking.hostel_id == admin.hostel_id, MealBooking.date == target_date)
    )
    bookings_map = {b.user_id: b for b in bookings_res.scalars().all()}

    # Get consumption records for this date
    c_query = select(ConsumptionRecord).where(
        ConsumptionRecord.hostel_id == admin.hostel_id,
        ConsumptionRecord.date == target_date,
    )
    if meal_type:
        c_query = c_query.where(ConsumptionRecord.meal_type == meal_type)
    c_res = await db.execute(c_query)
    c_records = c_res.scalars().all()

    # map (user_id, meal_type) -> record
    c_map = {(r.user_id, r.meal_type): r for r in c_records}

    # Applicable current prices
    b_price = await _get_applicable_price(db, admin.hostel_id, MealType.BREAKFAST)
    l_price = await _get_applicable_price(db, admin.hostel_id, MealType.LUNCH)
    d_price = await _get_applicable_price(db, admin.hostel_id, MealType.DINNER)

    rows = []
    for s in students:
        b_booking = bookings_map.get(s.id)
        
        c_breakfast = c_map.get((s.id, MealType.BREAKFAST))
        c_lunch = c_map.get((s.id, MealType.LUNCH))
        c_dinner = c_map.get((s.id, MealType.DINNER))

        rows.append({
            "user_id": s.id,
            "full_name": s.full_name,
            "room_number": s.room_number,
            "breakfast": {
                "booked": b_booking.breakfast_booked if b_booking else False,
                "consumed": c_breakfast.consumed if c_breakfast else False,
                "recorded": c_breakfast is not None,
                "price": c_breakfast.price_snapshot if (c_breakfast and c_breakfast.consumed) else b_price,
            },
            "lunch": {
                "booked": b_booking.lunch_booked if b_booking else False,
                "consumed": c_lunch.consumed if c_lunch else False,
                "recorded": c_lunch is not None,
                "price": c_lunch.price_snapshot if (c_lunch and c_lunch.consumed) else l_price,
            },
            "dinner": {
                "booked": b_booking.dinner_booked if b_booking else False,
                "consumed": c_dinner.consumed if c_dinner else False,
                "recorded": c_dinner is not None,
                "price": c_dinner.price_snapshot if (c_dinner and c_dinner.consumed) else d_price,
            },
        })

    return {
        "date": target_date,
        "total_students": len(students),
        "students": rows,
    }

@router.get("/student-expenses", response_model=StudentExpenseSummaryOut)
async def get_student_expenses(
    month: int | None = None,
    year: int | None = None,
    target_user_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    now_utc = datetime.now(timezone.utc)
    m = month or now_utc.month
    y = year or now_utc.year

    uid = current_user.id
    if target_user_id and current_user.role == UserRole.ADMIN:
        uid = target_user_id

    user_res = await db.execute(select(User).where(User.id == uid))
    student = user_res.scalar_one_or_none()
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    # Fetch consumption records for the month
    c_query = (
        select(ConsumptionRecord)
        .where(
            ConsumptionRecord.user_id == uid,
            extract("month", ConsumptionRecord.date) == m,
            extract("year", ConsumptionRecord.date) == y,
        )
        .order_by(ConsumptionRecord.date.desc())
    )
    c_res = await db.execute(c_query)
    c_records = c_res.scalars().all()

    # Fetch bookings for context
    b_query = (
        select(MealBooking)
        .where(
            MealBooking.user_id == uid,
            extract("month", MealBooking.date) == m,
            extract("year", MealBooking.date) == y,
        )
    )
    b_res = await db.execute(b_query)
    bookings_map = {b.date: b for b in b_res.scalars().all()}

    # Group by date
    days_data = {}
    for r in c_records:
        if r.date not in days_data:
            b = bookings_map.get(r.date)
            days_data[r.date] = {
                MealType.BREAKFAST: StudentMealStatus(meal_type=MealType.BREAKFAST, booked=b.breakfast_booked if b else False),
                MealType.LUNCH: StudentMealStatus(meal_type=MealType.LUNCH, booked=b.lunch_booked if b else False),
                MealType.DINNER: StudentMealStatus(meal_type=MealType.DINNER, booked=b.dinner_booked if b else False),
            }
        status_item = days_data[r.date][r.meal_type]
        status_item.consumed = r.consumed
        status_item.price_charged = r.price_snapshot if r.consumed else 0.0

    total_charges = 0.0
    total_consumed_count = 0
    days_list = []

    for d in sorted(days_data.keys(), reverse=True):
        m_map = days_data[d]
        b_stat = m_map[MealType.BREAKFAST]
        l_stat = m_map[MealType.LUNCH]
        d_stat = m_map[MealType.DINNER]

        day_total = b_stat.price_charged + l_stat.price_charged + d_stat.price_charged
        total_charges += day_total
        if b_stat.consumed:
            total_consumed_count += 1
        if l_stat.consumed:
            total_consumed_count += 1
        if d_stat.consumed:
            total_consumed_count += 1

        days_list.append(
            StudentDayExpenseOut(
                date=d,
                breakfast=b_stat,
                lunch=l_stat,
                dinner=d_stat,
                total_charge=day_total,
            )
        )

    return StudentExpenseSummaryOut(
        user_id=student.id,
        user_name=student.full_name,
        month=m,
        year=y,
        total_charges=total_charges,
        total_consumed_count=total_consumed_count,
        days=days_list,
    )
