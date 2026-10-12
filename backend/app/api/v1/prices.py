from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.user import User
from app.models.enums import MealType
from app.models.pricing import MealPrice, PriceHistory
from app.schemas.pricing import MealPricesOut, AllPricesUpdate, PriceHistoryOut
from app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/prices", tags=["Meal Prices"])

@router.get("/", response_model=MealPricesOut)
async def get_current_prices(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(MealPrice).where(MealPrice.hostel_id == current_user.hostel_id)
    res = await db.execute(query)
    prices = res.scalars().all()

    price_map = {p.meal_type: p.price for p in prices}
    effective_from = max((p.effective_from for p in prices), default=None) if prices else None

    return MealPricesOut(
        breakfast=price_map.get(MealType.BREAKFAST, 40.0),
        lunch=price_map.get(MealType.LUNCH, 80.0),
        dinner=price_map.get(MealType.DINNER, 70.0),
        effective_from=effective_from,
    )

@router.put("/", response_model=MealPricesOut)
async def update_prices(
    req: AllPricesUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    updates = [
        (MealType.BREAKFAST, req.breakfast),
        (MealType.LUNCH, req.lunch),
        (MealType.DINNER, req.dinner),
    ]

    now_utc = datetime.now(timezone.utc)

    from app.models.audit import AuditLog
    changed_items = []

    for meal_type, raw_price in updates:
        new_price = round(float(raw_price), 2)
        res = await db.execute(
            select(MealPrice).where(
                MealPrice.hostel_id == admin.hostel_id,
                MealPrice.meal_type == meal_type,
            )
        )
        p_row = res.scalar_one_or_none()
        old_price = p_row.price if p_row else 0.0

        if not p_row:
            p_row = MealPrice(
                hostel_id=admin.hostel_id,
                meal_type=meal_type,
                price=new_price,
                effective_from=now_utc,
            )
            db.add(p_row)
            changed_items.append(f"{meal_type.value}: initial ₹{new_price}")
        else:
            if p_row.price != new_price:
                # Log to PriceHistory for audit trail
                history_entry = PriceHistory(
                    hostel_id=admin.hostel_id,
                    meal_type=meal_type,
                    old_price=old_price,
                    new_price=new_price,
                    changed_by_user_id=admin.id,
                    changed_at=now_utc,
                )
                db.add(history_entry)
                p_row.price = new_price
                p_row.effective_from = now_utc
                changed_items.append(f"{meal_type.value}: ₹{old_price} -> ₹{new_price}")

    if changed_items:
        audit = AuditLog(
            user_id=admin.id,
            action="UPDATE_MEAL_PRICES",
            resource=f"hostel:{admin.hostel_id}:prices",
            details=f"Admin {admin.email} updated meal prices: {', '.join(changed_items)}",
        )
        db.add(audit)

    await db.commit()

    return MealPricesOut(
        breakfast=round(float(req.breakfast), 2),
        lunch=round(float(req.lunch), 2),
        dinner=round(float(req.dinner), 2),
        effective_from=now_utc,
    )


@router.get("/history", response_model=list[PriceHistoryOut])
async def get_price_history(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    query = (
        select(PriceHistory, User.full_name)
        .outerjoin(User, PriceHistory.changed_by_user_id == User.id)
        .where(PriceHistory.hostel_id == admin.hostel_id)
        .order_by(PriceHistory.changed_at.desc())
    )
    res = await db.execute(query)
    rows = res.all()

    out = []
    for ph, user_name in rows:
        out.append(
            PriceHistoryOut(
                id=ph.id,
                meal_type=ph.meal_type,
                old_price=ph.old_price,
                new_price=ph.new_price,
                changed_by_name=user_name,
                changed_at=ph.changed_at,
            )
        )
    return out
