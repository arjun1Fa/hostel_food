from datetime import datetime
from pydantic import BaseModel, ConfigDict

class HostelBase(BaseModel):
    name: str
    code: str
    address: str | None = None

class HostelOut(HostelBase):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
