from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import PyJWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.client import Client
from app.models.staff import Staff

# Два независимых потока авторизации. Токены не взаимозаменяемы: в payload
# лежит "type": "staff"|"client", и каждая зависимость проверяет своё значение.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
client_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/client/login")

# Схема, которая НЕ падает при отсутствии заголовка — для эндпоинтов,
# доступных и сотруднику, и клиенту (разбираем тип токена вручную).
any_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

_credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Не удалось подтвердить учётные данные",
    headers={"WWW-Authenticate": "Bearer"},
)


def _subject_id(token: str, expected_type: str) -> int:
    """Разбирает JWT и возвращает id субъекта, если тип токена совпал."""
    try:
        payload = decode_access_token(token)
    except PyJWTError:
        raise _credentials_exception

    if payload.get("type") != expected_type:
        raise _credentials_exception

    subject = payload.get("sub")
    if subject is None:
        raise _credentials_exception

    try:
        return int(subject)
    except (TypeError, ValueError):
        raise _credentials_exception


async def get_current_staff(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Staff:
    staff_id = _subject_id(token, "staff")

    result = await db.execute(select(Staff).where(Staff.staff_id == staff_id))
    staff = result.scalar_one_or_none()

    if staff is None or not staff.is_active:
        raise _credentials_exception

    return staff


async def get_current_admin(current_staff: Staff = Depends(get_current_staff)) -> Staff:
    """Только для управления сотрудниками — менеджер туда не ходит."""
    if current_staff.role != "admin":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, detail="Доступно только администратору"
        )
    return current_staff


async def get_current_client(
    token: str = Depends(client_oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Client:
    client_id = _subject_id(token, "client")

    result = await db.execute(select(Client).where(Client.client_id == client_id))
    client = result.scalar_one_or_none()

    if client is None or not client.is_registered:
        raise _credentials_exception

    return client


@dataclass(frozen=True)
class CurrentActor:
    """Кто сделал запрос — сотрудник или клиент.

    Нужен эндпоинтам, доступным обоим (баланс брони, смена статуса):
    сотрудник видит всё, клиент — только свои бронирования.
    """

    staff: Staff | None = None
    client: Client | None = None

    @property
    def is_staff(self) -> bool:
        return self.staff is not None

    def owns(self, client_id: int) -> bool:
        """Сотруднику доступно любое бронирование, клиенту — только своё."""
        return self.is_staff or (self.client is not None and self.client.client_id == client_id)


async def get_current_actor(
    token: str | None = Depends(any_oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> CurrentActor:
    if token is None:
        raise _credentials_exception

    try:
        payload = decode_access_token(token)
    except PyJWTError:
        raise _credentials_exception

    token_type = payload.get("type")
    if token_type == "staff":
        return CurrentActor(staff=await get_current_staff(token=token, db=db))
    if token_type == "client":
        return CurrentActor(client=await get_current_client(token=token, db=db))
    raise _credentials_exception
