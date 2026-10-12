from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.user import User
from app.models.audit import AuditLog
from app.schemas.audit import AuditLogOut
from app.api.deps import get_current_admin

router = APIRouter(prefix="/audit", tags=["Security & Audit Logs"])

@router.get("/logs", response_model=list[AuditLogOut])
async def get_audit_logs(
    action: str | None = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    """
    Returns structured security and administrative audit log entries.
    Requires administrator privileges.
    """
    query = (
        select(AuditLog, User.full_name)
        .outerjoin(User, AuditLog.user_id == User.id)
    )
    if action:
        query = query.where(AuditLog.action == action)
    
    query = query.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit)
    res = await db.execute(query)
    rows = res.all()

    out = []
    for log_item, user_name in rows:
        out.append(
            AuditLogOut(
                id=log_item.id,
                user_id=log_item.user_id,
                user_name=user_name,
                action=log_item.action,
                resource=log_item.resource,
                details=log_item.details,
                created_at=log_item.created_at,
            )
        )
    return out
