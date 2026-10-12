from pydantic import BaseModel, EmailStr

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    csrf_token: str | None = None

class TokenPayload(BaseModel):
    sub: str | None = None
    role: str | None = None
    type: str | None = None
    exp: int | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshTokenRequest(BaseModel):
    refresh_token: str | None = None

