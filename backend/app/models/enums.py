import enum

class UserRole(str, enum.Enum):
    ADMIN = "ADMIN"
    STUDENT = "STUDENT"

class MealType(str, enum.Enum):
    BREAKFAST = "BREAKFAST"
    LUNCH = "LUNCH"
    DINNER = "DINNER"

class NotificationType(str, enum.Enum):
    REMINDER = "REMINDER"
    MENU_UPDATE = "MENU_UPDATE"
    CHARGE_UPDATE = "CHARGE_UPDATE"
    SYSTEM = "SYSTEM"
