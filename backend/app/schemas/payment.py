from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.booking import BookingBalance


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


class CheckoutRequest(BaseModel):
    """Тело «оплаты картой».

    ВАЖНО: полный номер карты, срок и CVC сюда НЕ передаются и нигде не
    хранятся — шлюз демонстрационный, форма на клиенте нужна только для вида.
    На сервер приходят последние 4 цифры, чтобы платёж в истории выглядел
    как «карта ****1111», и этого достаточно.
    """

    card_last4: str = Field(pattern=r"^\d{4}$", description="Последние 4 цифры карты")
    cardholder: str | None = Field(default=None, max_length=100)


class CheckoutResult(BaseModel):
    """Ответ демо-шлюза: что списали, каким стал баланс и статус брони."""

    payment: PaymentRead
    balance: BookingBalance
    booking_status: str
