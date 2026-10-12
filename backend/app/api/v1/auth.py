import secrets
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    verify_password,
    dummy_verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    hash_token,
    decode_token,
)
from app.models.user import User, RefreshToken
from app.models.hostel import Hostel
from app.models.enums import UserRole
from app.models.audit import AuditLog
from app.schemas.auth import Token, LoginRequest, RefreshTokenRequest
from app.schemas.user import UserCreate, UserOut
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

def _set_auth_cookies(response: Response, raw_refresh: str) -> str:
    csrf_token = secrets.token_urlsafe(32)
    response.set_cookie(
        key=settings.COOKIE_REFRESH_NAME,
        value=raw_refresh,
        httponly=True,
        secure=settings.COOKIE_SECURE,
        samesite=settings.COOKIE_SAMESITE,
        max_age=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400,
        path=f"{settings.API_V1_STR}/auth",
    )
    response.set_cookie(
        key=settings.COOKIE_CSRF_NAME,
        value=csrf_token,
        httponly=False,  # JavaScript readable for X-CSRF-Token header in PWA/Web
        secure=settings.COOKIE_SECURE,
        samesite=settings.COOKIE_SAMESITE,
        max_age=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400,
        path="/",
    )
    return csrf_token

def _clear_auth_cookies(response: Response):
    response.delete_cookie(
        key=settings.COOKIE_REFRESH_NAME,
        path=f"{settings.API_V1_STR}/auth",
    )
    response.delete_cookie(
        key=settings.COOKIE_CSRF_NAME,
        path="/",
    )

@router.post("/login", response_model=Token)
async def login(
    req: LoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()

    if not user:
        # Constant-time mitigation against user enumeration
        dummy_verify_password(req.password)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated. Please contact hostel administrator."
        )

    access_token = create_access_token(subject=user.id, role=user.role.value)
    raw_refresh, token_hash, expires_at = create_refresh_token(subject=user.id)

    # Store refresh token record
    db_token = RefreshToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=expires_at,
        revoked=False,
    )
    db.add(db_token)

    # Log login event
    audit = AuditLog(
        user_id=user.id,
        action="LOGIN_SUCCESS",
        resource="auth:login",
        details=f"User {user.email} successfully logged in as {user.role.value}.",
    )
    db.add(audit)
    await db.commit()

    csrf_token = _set_auth_cookies(response, raw_refresh)

    return Token(
        access_token=access_token,
        refresh_token=raw_refresh,
        csrf_token=csrf_token,
    )

@router.post("/refresh", response_model=Token)
async def refresh_token(
    request: Request,
    response: Response,
    req: RefreshTokenRequest = None,
    db: AsyncSession = Depends(get_db)
):
    # Extract refresh token: check body first, then fallback to HttpOnly cookie for Web/PWA
    refresh_tok_str = None
    if req and req.refresh_token:
        refresh_tok_str = req.refresh_token
    else:
        cookie_tok = request.cookies.get(settings.COOKIE_REFRESH_NAME)
        if cookie_tok:
            # If cookie authentication is used, enforce CSRF protection
            expected_csrf = request.cookies.get(settings.COOKIE_CSRF_NAME)
            received_csrf = request.headers.get("x-csrf-token")
            if not expected_csrf or received_csrf != expected_csrf:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="CSRF validation failed for cookie-based refresh operation.",
                )
            refresh_tok_str = cookie_tok

    if not refresh_tok_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token required (via payload or cookie)."
        )

    try:
        payload = decode_token(refresh_tok_str)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = int(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    token_hash = hash_token(refresh_tok_str)

    # Check for unrevoked active token
    res = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked == False,
        )
    )
    stored_token = res.scalar_one_or_none()

    if not stored_token:
        # Check if this token was already revoked: indicates potential token reuse attack!
        reuse_res = await db.execute(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash,
                RefreshToken.revoked == True,
            )
        )
        compromised_token = reuse_res.scalar_one_or_none()
        if compromised_token:
            # Threat response: Revoke ALL active refresh tokens for this user!
            await db.execute(
                update(RefreshToken)
                .where(RefreshToken.user_id == compromised_token.user_id)
                .values(revoked=True)
            )
            audit = AuditLog(
                user_id=compromised_token.user_id,
                action="TOKEN_REUSE_DETECTED",
                resource="auth:refresh",
                details="Revoked refresh token reuse detected. Revoking all active sessions for user.",
            )
            db.add(audit)
            await db.commit()
            _clear_auth_cookies(response)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Security violation: Revoked token presented. All sessions terminated."
            )

        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired or revoked")

    if stored_token.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        stored_token.revoked = True
        await db.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired")

    # Rotate old refresh token
    stored_token.revoked = True

    # Fetch user
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User inactive or not found")

    new_access_token = create_access_token(subject=user.id, role=user.role.value)
    raw_new_refresh, new_token_hash, expires_at = create_refresh_token(subject=user.id)

    new_db_token = RefreshToken(
        user_id=user.id,
        token_hash=new_token_hash,
        expires_at=expires_at,
        revoked=False,
    )
    db.add(new_db_token)
    await db.commit()

    csrf_token = _set_auth_cookies(response, raw_new_refresh)

    return Token(
        access_token=new_access_token,
        refresh_token=raw_new_refresh,
        csrf_token=csrf_token,
    )

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register_student(req: UserCreate, db: AsyncSession = Depends(get_db)):
    # Check if email taken
    existing = await db.execute(select(User).where(User.email == req.email.lower()))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email is already registered")

    # Get single hostel
    hostel_res = await db.execute(select(Hostel).limit(1))
    hostel = hostel_res.scalar_one_or_none()
    if not hostel:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="No active hostel configured")

    new_user = User(
        hostel_id=hostel.id,
        email=req.email.lower(),
        full_name=req.full_name,
        hashed_password=get_password_hash(req.password),
        role=UserRole.STUDENT,
        room_number=req.room_number,
        phone_number=req.phone_number,
        is_active=True,
    )
    db.add(new_user)
    await db.flush()

    audit = AuditLog(
        user_id=new_user.id,
        action="USER_REGISTRATION",
        resource=f"user:{new_user.id}",
        details=f"Student {new_user.email} registered for hostel {hostel.id}.",
    )
    db.add(audit)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/logout")
async def logout(
    request: Request,
    response: Response,
    req: RefreshTokenRequest = None,
    db: AsyncSession = Depends(get_db)
):
    refresh_tok_str = None
    if req and req.refresh_token:
        refresh_tok_str = req.refresh_token
    else:
        refresh_tok_str = request.cookies.get(settings.COOKIE_REFRESH_NAME)

    if refresh_tok_str:
        token_hash = hash_token(refresh_tok_str)
        res = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
        token = res.scalar_one_or_none()
        if token:
            token.revoked = True
            audit = AuditLog(
                user_id=token.user_id,
                action="LOGOUT",
                resource="auth:logout",
                details="Session refresh token revoked on logout.",
            )
            db.add(audit)
            await db.commit()

    _clear_auth_cookies(response)
    return {"message": "Logged out successfully"}

@router.post("/logout-all")
async def logout_all(
    response: Response,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Revokes all active sessions and device tokens for the current user."""
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == current_user.id)
        .values(revoked=True)
    )
    audit = AuditLog(
        user_id=current_user.id,
        action="LOGOUT_ALL_DEVICES",
        resource="auth:logout-all",
        details="User revoked all active sessions across all devices.",
    )
    db.add(audit)
    await db.commit()
    _clear_auth_cookies(response)
    return {"message": "All active sessions revoked successfully"}

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
