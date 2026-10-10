from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, hash_token, decode_token
from app.models.user import User, RefreshToken
from app.models.hostel import Hostel
from app.models.enums import UserRole
from app.schemas.auth import Token, LoginRequest, RefreshTokenRequest
from app.schemas.user import UserCreate, UserOut
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=Token)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated. Please contact hostel administrator.")

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
    await db.commit()

    return Token(access_token=access_token, refresh_token=raw_refresh)

@router.post("/refresh", response_model=Token)
async def refresh_token(req: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(req.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = int(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    token_hash = hash_token(req.refresh_token)
    res = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash, RefreshToken.revoked == False))
    stored_token = res.scalar_one_or_none()

    if not stored_token or stored_token.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired or revoked")

    # Revoke old refresh token (Token Rotation)
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

    return Token(access_token=new_access_token, refresh_token=raw_new_refresh)

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register_student(req: UserCreate, db: AsyncSession = Depends(get_db)):
    # Check if email taken
    existing = await db.execute(select(User).where(User.email == req.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email is already registered")

    # Get single hostel
    hostel_res = await db.execute(select(Hostel).limit(1))
    hostel = hostel_res.scalar_one_or_none()
    if not hostel:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="No active hostel configured")

    new_user = User(
        hostel_id=hostel.id,
        email=req.email,
        full_name=req.full_name,
        hashed_password=get_password_hash(req.password),
        role=UserRole.STUDENT,
        room_number=req.room_number,
        phone_number=req.phone_number,
        is_active=True,
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/logout")
async def logout(req: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    token_hash = hash_token(req.refresh_token)
    res = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    token = res.scalar_one_or_none()
    if token:
        token.revoked = True
        await db.commit()
    return {"message": "Logged out successfully"}

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
