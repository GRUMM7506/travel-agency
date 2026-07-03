from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

StaffRole = Literal["admin", "manager"]


# ---------------------------------------------------------------------------
# Сотрудники
# ---------------------------------------------------------------------------


class StaffLogin(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class StaffRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    staff_id: int
    full_name: str
    email: str
    role: str
    is_active: bool


class StaffCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=6, max_length=72)
    role: StaffRole = "manager"
    is_active: bool = True


class StaffUpdate(BaseModel):
    """Пароль здесь опционален — пустой/отсутствующий означает «не менять»."""

    full_name: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=100)
    password: str | None = Field(default=None, min_length=6, max_length=72)
    role: StaffRole = "manager"
    is_active: bool = True


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=6, max_length=72)


# ---------------------------------------------------------------------------
# Клиенты
# ---------------------------------------------------------------------------


class ClientRegister(BaseModel):
    first_name: str = Field(min_length=1, max_length=50)
    last_name: str = Field(min_length=1, max_length=50)
    email: str = Field(min_length=3, max_length=100)
    phone: str | None = Field(default=None, max_length=20)
    password: str = Field(min_length=6, max_length=72)


class ClientLogin(BaseModel):
    email: str
    password: str


class ClientAccountRead(BaseModel):
    """Данные залогиненного клиента — без password_hash."""

    model_config = ConfigDict(from_attributes=True)

    client_id: int
    first_name: str
    last_name: str
    middle_name: str | None = None
    email: str | None = None
    phone: str | None = None
    passport: str | None = None
    foreign_passport: str | None = None
    address: str | None = None


class ClientProfileUpdate(BaseModel):
    """Что клиент может отредактировать у себя сам.

    Email не меняется — это логин; смена логина потребовала бы подтверждения
    почты, чего в MVP нет.
    """

    first_name: str = Field(min_length=1, max_length=50)
    last_name: str = Field(min_length=1, max_length=50)
    middle_name: str | None = Field(default=None, max_length=50)
    phone: str | None = Field(default=None, max_length=20)
    address: str | None = Field(default=None, max_length=150)
    passport: str | None = Field(default=None, max_length=30)
    foreign_passport: str | None = Field(default=None, max_length=30)
