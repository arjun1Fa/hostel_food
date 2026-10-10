from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.user import User
from app.models.enums import UserRole, MealType
from app.models.menu import Menu, MenuDish
from app.schemas.menu import MenuCreate, MenuUpdate, MenuOut, DayMealsOut
from app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/menus", tags=["Menu Management"])

@router.get("/daily/{target_date}", response_model=DayMealsOut)
async def get_daily_menu(
    target_date: date,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = (
        select(Menu)
        .options(selectinload(Menu.dishes))
        .where(Menu.hostel_id == current_user.hostel_id, Menu.date == target_date)
    )
    if current_user.role == UserRole.STUDENT:
        query = query.where(Menu.is_published == True)

    result = await db.execute(query)
    menus = result.scalars().all()

    meals_map = {m.meal_type: m for m in menus}

    return DayMealsOut(
        date=target_date,
        breakfast=meals_map.get(MealType.BREAKFAST),
        lunch=meals_map.get(MealType.LUNCH),
        dinner=meals_map.get(MealType.DINNER),
    )

@router.get("/", response_model=list[MenuOut])
async def list_menus(
    from_date: date | None = None,
    to_date: date | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = (
        select(Menu)
        .options(selectinload(Menu.dishes))
        .where(Menu.hostel_id == current_user.hostel_id)
    )
    if from_date:
        query = query.where(Menu.date >= from_date)
    if to_date:
        query = query.where(Menu.date <= to_date)
    if current_user.role == UserRole.STUDENT:
        query = query.where(Menu.is_published == True)

    query = query.order_by(Menu.date.desc(), Menu.meal_type)
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/", response_model=MenuOut, status_code=status.HTTP_201_CREATED)
async def create_or_update_menu(
    req: MenuCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    # Check if a menu already exists for this hostel, date, and meal_type
    query = (
        select(Menu)
        .options(selectinload(Menu.dishes))
        .where(
            Menu.hostel_id == admin.hostel_id,
            Menu.date == req.date,
            Menu.meal_type == req.meal_type,
        )
    )
    res = await db.execute(query)
    existing_menu = res.scalar_one_or_none()

    if existing_menu:
        # Update existing menu
        existing_menu.title = req.title
        existing_menu.description = req.description
        existing_menu.image_url = req.image_url
        existing_menu.dietary_tags = req.dietary_tags
        existing_menu.is_published = req.is_published

        # Replace dishes
        existing_menu.dishes.clear()
        for d in req.dishes:
            existing_menu.dishes.append(
                MenuDish(name=d.name, category=d.category, is_vegetarian=d.is_vegetarian)
            )
        await db.commit()
        
        # Reload with selectinload to avoid lazy-loading outside greenlet
        reloaded = await db.execute(
            select(Menu).options(selectinload(Menu.dishes)).where(Menu.id == existing_menu.id)
        )
        return reloaded.scalar_one()
    else:
        new_menu = Menu(
            hostel_id=admin.hostel_id,
            date=req.date,
            meal_type=req.meal_type,
            title=req.title,
            description=req.description,
            image_url=req.image_url,
            dietary_tags=req.dietary_tags,
            is_published=req.is_published,
        )
        for d in req.dishes:
            new_menu.dishes.append(
                MenuDish(name=d.name, category=d.category, is_vegetarian=d.is_vegetarian)
            )
        db.add(new_menu)
        await db.commit()
        
        # Reload with selectinload to avoid lazy-loading outside greenlet
        reloaded = await db.execute(
            select(Menu).options(selectinload(Menu.dishes)).where(Menu.id == new_menu.id)
        )
        return reloaded.scalar_one()

@router.patch("/{menu_id}/publish", response_model=MenuOut)
async def toggle_menu_publish(
    menu_id: int,
    is_published: bool,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    query = select(Menu).options(selectinload(Menu.dishes)).where(Menu.id == menu_id, Menu.hostel_id == admin.hostel_id)
    res = await db.execute(query)
    menu = res.scalar_one_or_none()
    if not menu:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu not found")
    
    menu.is_published = is_published
    await db.commit()
    
    reloaded = await db.execute(
        select(Menu).options(selectinload(Menu.dishes)).where(Menu.id == menu.id)
    )
    return reloaded.scalar_one()

@router.delete("/{menu_id}")
async def delete_menu(
    menu_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    query = select(Menu).where(Menu.id == menu_id, Menu.hostel_id == admin.hostel_id)
    res = await db.execute(query)
    menu = res.scalar_one_or_none()
    if not menu:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu not found")
    
    await db.delete(menu)
    await db.commit()
    return {"message": "Menu deleted successfully"}
