from datetime import date

from pydantic import BaseModel, ConfigDict


class ClientBase(BaseModel):
    last_name: str
    first_name: str
    middle_name: str | None = None
    birth_date: date | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    passport: str | None = None
    foreign_passport: str | None = None
    notes: str | None = None


class ClientCreate(ClientBase):
    pass


class ClientUpdate(ClientBase):
    pass


class ClientRead(ClientBase):
    model_config = ConfigDict(from_attributes=True)
    client_id: int
