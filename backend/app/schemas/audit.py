from datetime import datetime
from pydantic import BaseModel, ConfigDict

class AuditLogOut(BaseModel):
    id: int
    user_id: int | None = None
    user_name: str | None = None
    action: str
    resource: str
    details: str | None = None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
