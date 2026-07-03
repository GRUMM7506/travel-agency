from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class PaymentBase(BaseModel):
    booking_id: int
    payment_date: date | None = None
    amount: Decimal
    payment_method: str | None = None
    notes: str | None = None


class PaymentCreate(PaymentBase):
    pass


class PaymentUpdate(PaymentBase):
    pass


class PaymentRead(PaymentBase):
    model_config = ConfigDict(from_attributes=True)
    payment_id: int
    payment_date: date


class PaymentRequisites(BaseModel):
    """Куда клиент переводит деньги. Заполняется из .env, не хардкодится в UI."""

    recipient: str
    card_number: str
    bank_name: str
    comment: str
