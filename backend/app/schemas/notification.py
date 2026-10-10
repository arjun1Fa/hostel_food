from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.models.enums import NotificationType

class NotificationOut(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    type: NotificationType
    is_read: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class DeviceTokenCreate(BaseModel):
    token: str
    platform: str = "flutter"
