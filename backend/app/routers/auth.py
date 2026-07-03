from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_client, get_current_staff
from app.core.database import get_db
from app.core.security import create_access_token, hash_password, verify_password
from app.models.client import Client
from app.models.staff import Staff
from app.schemas.auth import (
    ClientAccountRead,
    ClientLogin,
    ClientProfileUpdate,
    ClientRegister,
    PasswordChange,
    StaffLogin,
    StaffRead,
    Token,
)

router = APIRouter(prefix="/auth", tags=["Auth"])

_bad_credentials = HTTPException(
    status.HTTP_401_UNAUTHORIZED, detail="Неверный email или пароль"
)


async def _client_by_email(db: AsyncSession, email: str) -> Client | None:
    """Email клиента не уникален на уровне БД (сотрудник может завести дубль),
    поэтому ищем регистронезависимо и берём первого подходящего."""
    stmt = select(Client).where(func.lower(Client.email) == email.strip().lower())
    result = await db.execute(stmt)
    return result.scalars().first()


# ---------------------------------------------------------------------------
# Сотрудники
# ---------------------------------------------------------------------------


@router.post("/login", response_model=Token)
async def login(data: StaffLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Staff).where(Staff.email == data.email))
    staff = result.scalar_one_or_none()

    if staff is None or not verify_password(data.password, staff.password_hash):
        raise _bad_credentials
    if not staff.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Учётная запись отключена")

    access_token = create_access_token({"sub": str(staff.staff_id), "type": "staff"})
    return Token(access_token=access_token)


@router.get("/me", response_model=StaffRead)
async def me(current_staff: Staff = Depends(get_current_staff)):
    return current_staff


@router.post("/password", status_code=status.HTTP_204_NO_CONTENT)
async def change_own_password(
    data: PasswordChange,
    current_staff: Staff = Depends(get_current_staff),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(data.current_password, current_staff.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Текущий пароль неверен")
    current_staff.password_hash = hash_password(data.new_password)
    await db.commit()


# ---------------------------------------------------------------------------
# Клиенты
# ---------------------------------------------------------------------------


@router.post("/client/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def client_register(data: ClientRegister, db: AsyncSession = Depends(get_db)):
    """Регистрация клиента.

    Если карточка с таким email уже заведена сотрудником, но пароля у неё нет —
    привязываем пароль к ней, а не плодим дубль: это тот же человек, и его
    прошлые бронирования должны остаться видны в личном кабинете.
    Если пароль уже стоит — значит, аккаунт есть, отправляем логиниться.
    """
    existing = await _client_by_email(db, data.email)

    if existing is not None and existing.is_registered:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            detail="Клиент с таким email уже зарегистрирован — попробуйте войти",
        )

    if existing is not None:
        client = existing
        client.first_name = data.first_name
        client.last_name = data.last_name
        if data.phone:
            client.phone = data.phone
    else:
        client = Client(
            first_name=data.first_name,
            last_name=data.last_name,
            email=data.email.strip(),
            phone=data.phone,
        )
        db.add(client)

    client.password_hash = hash_password(data.password)
    client.is_registered = True

    await db.commit()
    await db.refresh(client)

    access_token = create_access_token({"sub": str(client.client_id), "type": "client"})
    return Token(access_token=access_token)


@router.post("/client/login", response_model=Token)
async def client_login(data: ClientLogin, db: AsyncSession = Depends(get_db)):
    client = await _client_by_email(db, data.email)

    if client is None or not client.is_registered or client.password_hash is None:
        raise _bad_credentials
    if not verify_password(data.password, client.password_hash):
        raise _bad_credentials

    access_token = create_access_token({"sub": str(client.client_id), "type": "client"})
    return Token(access_token=access_token)


@router.get("/client/me", response_model=ClientAccountRead)
async def client_me(current_client: Client = Depends(get_current_client)):
    return current_client


@router.put("/client/me", response_model=ClientAccountRead)
async def update_client_profile(
    data: ClientProfileUpdate,
    current_client: Client = Depends(get_current_client),
    db: AsyncSession = Depends(get_db),
):
    for field, value in data.model_dump().items():
        setattr(current_client, field, value)
    await db.commit()
    await db.refresh(current_client)
    return current_client


@router.post("/client/password", status_code=status.HTTP_204_NO_CONTENT)
async def change_client_password(
    data: PasswordChange,
    current_client: Client = Depends(get_current_client),
    db: AsyncSession = Depends(get_db),
):
    if current_client.password_hash is None or not verify_password(
        data.current_password, current_client.password_hash
    ):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Текущий пароль неверен")
    current_client.password_hash = hash_password(data.new_password)
    await db.commit()
