from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.config import settings
from app.core.security import get_password_hash
from app.core.timezone import get_today_ist, get_tomorrow_ist
from app.models.hostel import Hostel
from app.models.user import User
from app.models.enums import UserRole, MealType
from app.models.pricing import MealPrice
from app.models.menu import Menu, MenuDish

async def bootstrap_app(db: AsyncSession) -> dict:
    """
    Bootstraps the single-hostel deployment:
    1. Ensures default hostel exists.
    2. Ensures default Admin exists.
    3. Ensures default meal prices are configured.
    4. Seeds initial sample students and menus for today & tomorrow if empty.
    """
    # 1. Hostel
    res = await db.execute(select(Hostel).limit(1))
    hostel = res.scalar_one_or_none()
    if not hostel:
        hostel = Hostel(
            name=settings.DEFAULT_HOSTEL_NAME,
            code=settings.DEFAULT_HOSTEL_CODE,
            address="Campus Block 4, North Wing",
        )
        db.add(hostel)
        await db.flush()

    # 2. Admin User
    admin_res = await db.execute(select(User).where(User.email == settings.ADMIN_EMAIL))
    admin = admin_res.scalar_one_or_none()
    if not admin:
        admin = User(
            hostel_id=hostel.id,
            email=settings.ADMIN_EMAIL,
            full_name=settings.ADMIN_NAME,
            hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
            role=UserRole.ADMIN,
            room_number="Admin Office",
            phone_number="+91 98765 43210",
            is_active=True,
        )
        db.add(admin)
        await db.flush()

    # 3. Default Prices
    price_defaults = [
        (MealType.BREAKFAST, 40.0),
        (MealType.LUNCH, 80.0),
        (MealType.DINNER, 70.0),
    ]
    for meal_type, default_price in price_defaults:
        p_res = await db.execute(
            select(MealPrice).where(MealPrice.hostel_id == hostel.id, MealPrice.meal_type == meal_type)
        )
        if not p_res.scalar_one_or_none():
            price_row = MealPrice(
                hostel_id=hostel.id,
                meal_type=meal_type,
                price=default_price,
            )
            db.add(price_row)

    # 4. Seed demo students if no students exist
    students_res = await db.execute(select(User).where(User.role == UserRole.STUDENT).limit(1))
    if not students_res.scalar_one_or_none():
        demo_students = [
            ("arjun@hostel.edu", "Arjun Sharma", "A-101", "+91 98111 22334"),
            ("priya@hostel.edu", "Priya Patel", "B-204", "+91 98222 33445"),
            ("rahul@hostel.edu", "Rahul Verma", "A-102", "+91 98333 44556"),
            ("sneha@hostel.edu", "Sneha Rao", "B-205", "+91 98444 55667"),
        ]
        for email, name, room, phone in demo_students:
            student = User(
                hostel_id=hostel.id,
                email=email,
                full_name=name,
                hashed_password=get_password_hash("Student@123"),
                role=UserRole.STUDENT,
                room_number=room,
                phone_number=phone,
                is_active=True,
            )
            db.add(student)

    # 5. Seed sample menus for today and tomorrow if empty
    today = get_today_ist()
    tomorrow = get_tomorrow_ist()

    menu_count_res = await db.execute(select(Menu).limit(1))
    if not menu_count_res.scalar_one_or_none():
        sample_menus = [
            # Today's menus
            (today, MealType.BREAKFAST, "South Indian Delight", "Freshly steamed idlis, crispy medu vada, and rich sambar", "High Protein, Vegetarian", [
                ("Steamed Rice Idli", "Main", True),
                ("Medu Vada", "Side", True),
                ("Vegetable Sambar", "Side", True),
                ("Coconut & Tomato Chutney", "Condiment", True),
                ("Filter Coffee / Tea", "Beverage", True),
            ]),
            (today, MealType.LUNCH, "Royal Thali Feast", "Paneer butter masala, yellow dal tadka, jeera rice, and hot phulkas", "Balanced, Rich Fiber", [
                ("Paneer Butter Masala", "Main", True),
                ("Dal Tadka", "Main", True),
                ("Jeera Rice", "Rice", True),
                ("Fresh Tawa Roti", "Bread", True),
                ("Cucumber Raita & Salad", "Side", True),
                ("Gulab Jamun", "Dessert", True),
            ]),
            (today, MealType.DINNER, "Comfort Khichdi & Curry", "Moong dal khichdi with kadhi, roasted papad, and seasonal veg sabzi", "Light, Easy Digest", [
                ("Special Moong Dal Khichdi", "Main", True),
                ("Gujarati Style Kadhi", "Main", True),
                ("Aloo Gobi Dry", "Side", True),
                ("Roasted Urad Papad", "Side", True),
                ("Fresh Curd", "Side", True),
            ]),
            # Tomorrow's menus
            (tomorrow, MealType.BREAKFAST, "Poha & Paratha Combo", "Indori batata poha served with aloo stuffed parathas and curd", "Vegetarian, Hearty", [
                ("Indori Batata Poha", "Main", True),
                ("Aloo Paratha", "Main", True),
                ("Fresh Dahi (Curd)", "Side", True),
                ("Green Mint Chutney", "Condiment", True),
                ("Ginger Masala Chai", "Beverage", True),
            ]),
            (tomorrow, MealType.LUNCH, "Punjabi Rajma Chawal Special", "Slow-cooked Kashmiri rajma with fragrant basmati rice, boondi raita", "High Protein, Traditional", [
                ("Kashmiri Rajma Masala", "Main", True),
                ("Steamed Basmati Rice", "Rice", True),
                ("Mixed Vegetable Poriyal", "Side", True),
                ("Boondi Raita", "Side", True),
                ("Tandoori Roti", "Bread", True),
            ]),
            (tomorrow, MealType.DINNER, "Veg Biryani & Shahi Paneer", "Fragrant dum biryani with rich gravy, mirchi ka salan, and kheer", "Special Dinner, Vegetarian", [
                ("Hyderabadi Dum Veg Biryani", "Main", True),
                ("Shahi Paneer Gravy", "Main", True),
                ("Mirchi Ka Salan", "Side", True),
                ("Onion & Tomato Raita", "Side", True),
                ("Rice Kheer", "Dessert", True),
            ]),
        ]

        for m_date, m_type, m_title, m_desc, m_tags, dishes in sample_menus:
            menu = Menu(
                hostel_id=hostel.id,
                date=m_date,
                meal_type=m_type,
                title=m_title,
                description=m_desc,
                dietary_tags=m_tags,
                is_published=True,
            )
            db.add(menu)
            await db.flush()
            for dish_name, dish_cat, is_veg in dishes:
                dish = MenuDish(
                    menu_id=menu.id,
                    name=dish_name,
                    category=dish_cat,
                    is_vegetarian=is_veg,
                )
                db.add(dish)

    await db.commit()
    return {
        "status": "ready",
        "hostel": hostel.name,
        "admin_email": admin.email,
    }
