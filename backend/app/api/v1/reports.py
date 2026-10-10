import io
import csv
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, extract
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.user import User
from app.models.enums import UserRole, MealType
from app.models.hostel import Hostel
from app.models.menu import Menu
from app.models.pricing import MealPrice
from app.models.booking import MealBooking
from app.models.consumption import ConsumptionRecord
from app.schemas.report import KitchenPrepSheetOut, KitchenPrepItem, DailyReportOut, MealReportRow, MonthlyReportOut
from app.api.deps import get_current_admin

router = APIRouter(prefix="/reports", tags=["Reports & Kitchen Preparation"])

@router.get("/kitchen-prep/{target_date}", response_model=KitchenPrepSheetOut)
async def get_kitchen_prep_sheet(
    target_date: date,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    # Fetch hostel
    hostel_res = await db.execute(select(Hostel).where(Hostel.id == admin.hostel_id))
    hostel = hostel_res.scalar_one_or_none()
    hostel_name = hostel.name if hostel else "Hostel Campus"

    # Fetch menus for date
    menu_res = await db.execute(
        select(Menu)
        .options(selectinload(Menu.dishes))
        .where(Menu.hostel_id == admin.hostel_id, Menu.date == target_date)
    )
    menus = {m.meal_type: m for m in menu_res.scalars().all()}

    # Fetch total students
    stud_res = await db.execute(
        select(User).where(User.hostel_id == admin.hostel_id, User.role == UserRole.STUDENT, User.is_active == True)
    )
    active_students = stud_res.scalars().all()

    # Fetch bookings for date
    book_res = await db.execute(
        select(MealBooking).where(MealBooking.hostel_id == admin.hostel_id, MealBooking.date == target_date)
    )
    bookings = book_res.scalars().all()

    b_portions = sum(1 for b in bookings if b.breakfast_booked)
    l_portions = sum(1 for b in bookings if b.lunch_booked)
    d_portions = sum(1 for b in bookings if b.dinner_booked)

    items = []
    for mt, count in [(MealType.BREAKFAST, b_portions), (MealType.LUNCH, l_portions), (MealType.DINNER, d_portions)]:
        menu = menus.get(mt)
        items.append(
            KitchenPrepItem(
                meal_type=mt,
                menu_title=menu.title if menu else "Menu Not Configured",
                dish_names=[d.name for d in menu.dishes] if menu else [],
                total_portions=count,
                published=menu.is_published if menu else False,
            )
        )

    return KitchenPrepSheetOut(
        date=target_date,
        hostel_name=hostel_name,
        items=items,
        total_active_students=len(active_students),
        total_bookings_day=b_portions + l_portions + d_portions,
    )

@router.get("/daily/{target_date}", response_model=DailyReportOut)
async def get_daily_report(
    target_date: date,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    # Fetch bookings
    b_res = await db.execute(
        select(MealBooking).where(MealBooking.hostel_id == admin.hostel_id, MealBooking.date == target_date)
    )
    bookings = b_res.scalars().all()

    # Fetch consumption
    c_res = await db.execute(
        select(ConsumptionRecord).where(ConsumptionRecord.hostel_id == admin.hostel_id, ConsumptionRecord.date == target_date)
    )
    consumptions = c_res.scalars().all()

    # Prices
    p_res = await db.execute(select(MealPrice).where(MealPrice.hostel_id == admin.hostel_id))
    prices = {p.meal_type: p.price for p in p_res.scalars().all()}

    def build_row(meal_type: MealType, booked_count: int) -> MealReportRow:
        meal_c = [c for c in consumptions if c.meal_type == meal_type]
        consumed_count = sum(1 for c in meal_c if c.consumed)
        total_charge = sum(c.price_snapshot for c in meal_c if c.consumed)
        unit_price = prices.get(meal_type, 40.0)
        unrecorded = max(0, booked_count - len(meal_c))
        return MealReportRow(
            date=target_date,
            meal_type=meal_type,
            booked_count=booked_count,
            consumed_count=consumed_count,
            unrecorded_count=unrecorded,
            unit_price=unit_price,
            total_charge=total_charge,
        )

    b_row = build_row(MealType.BREAKFAST, sum(1 for b in bookings if b.breakfast_booked))
    l_row = build_row(MealType.LUNCH, sum(1 for b in bookings if b.lunch_booked))
    d_row = build_row(MealType.DINNER, sum(1 for b in bookings if b.dinner_booked))

    return DailyReportOut(
        date=target_date,
        breakfast=b_row,
        lunch=l_row,
        dinner=d_row,
        total_day_charges=b_row.total_charge + l_row.total_charge + d_row.total_charge,
    )

@router.get("/monthly", response_model=MonthlyReportOut)
async def get_monthly_report(
    month: int | None = None,
    year: int | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    now_utc = datetime.now(timezone.utc)
    m = month or now_utc.month
    y = year or now_utc.year

    stud_res = await db.execute(
        select(User).where(User.hostel_id == admin.hostel_id, User.role == UserRole.STUDENT, User.is_active == True)
    )
    students = stud_res.scalars().all()

    c_res = await db.execute(
        select(ConsumptionRecord).where(
            ConsumptionRecord.hostel_id == admin.hostel_id,
            extract("month", ConsumptionRecord.date) == m,
            extract("year", ConsumptionRecord.date) == y,
            ConsumptionRecord.consumed == True,
        )
    )
    consumed_records = c_res.scalars().all()

    b_count = sum(1 for c in consumed_records if c.meal_type == MealType.BREAKFAST)
    l_count = sum(1 for c in consumed_records if c.meal_type == MealType.LUNCH)
    d_count = sum(1 for c in consumed_records if c.meal_type == MealType.DINNER)
    total_revenue = sum(c.price_snapshot for c in consumed_records)

    return MonthlyReportOut(
        year=y,
        month=m,
        total_breakfast_consumed=b_count,
        total_lunch_consumed=l_count,
        total_dinner_consumed=d_count,
        total_revenue_charges=total_revenue,
        student_count=len(students),
    )

@router.get("/export-csv")
async def export_csv_report(
    target_date: date,
    report_type: str = "kitchen_prep",  # "kitchen_prep" or "consumption"
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    output = io.StringIO()
    writer = csv.writer(output)

    if report_type == "kitchen_prep":
        prep_sheet = await get_kitchen_prep_sheet(target_date, db, admin)
        writer.writerow(["Kitchen Preparation Sheet", str(target_date)])
        writer.writerow(["Hostel", prep_sheet.hostel_name])
        writer.writerow(["Meal Type", "Portions to Prepare", "Menu Title", "Dishes", "Published"])
        for item in prep_sheet.items:
            writer.writerow([
                item.meal_type.value,
                item.total_portions,
                item.menu_title,
                ", ".join(item.dish_names),
                "YES" if item.published else "NO",
            ])
        filename = f"kitchen_prep_{target_date}.csv"
    else:
        # Consumption export
        query = (
            select(ConsumptionRecord, User.full_name, User.room_number)
            .join(User, ConsumptionRecord.user_id == User.id)
            .where(ConsumptionRecord.hostel_id == admin.hostel_id, ConsumptionRecord.date == target_date)
            .order_by(User.room_number, User.full_name)
        )
        res = await db.execute(query)
        records = res.all()
        writer.writerow(["Student ID", "Full Name", "Room", "Meal Type", "Consumed", "Charged (INR)", "Recorded At"])
        for c, name, room in records:
            writer.writerow([
                c.user_id,
                name,
                room or "-",
                c.meal_type.value,
                "YES" if c.consumed else "NO",
                c.price_snapshot,
                c.recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
            ])
        filename = f"consumption_{target_date}.csv"

    output.seek(0)
    return Response(
        content=output.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
