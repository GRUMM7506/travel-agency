from datetime import date
from decimal import Decimal
from typing import Literal, get_args

from pydantic import BaseModel, ConfigDict, Field

#: Полный жизненный цикл брони. Порядок = типичный путь заявки.
#: «заявка»/«ожидает оплаты»/«на проверке» появляются, когда бронирует сам клиент;
#: остальные выставляет сотрудник.
BookingStatus = Literal[
    "заявка",
    "ожидает оплаты",
    "на проверке",
    "оформлен",
    "оплачен",
    "завершён",
    "отменён",
]

BOOKING_STATUSES: tuple[str, ...] = get_args(BookingStatus)

#: Статусы, которые клиент вправе выставить сам на СВОЁ бронирование.
#: Всё остальное (подтверждение оплаты, завершение) — только сотрудник.
CLIENT_ALLOWED_STATUSES: frozenset[str] = frozenset({"на проверке", "отменён"})


class BookingBase(BaseModel):
    client_id: int
    tour_id: int
    booking_date: date | None = None
    people_count: int = Field(gt=0)
    discount_percent: Decimal = Decimal("0")
    commission_percent: Decimal = Decimal("10")
    status: BookingStatus = "оформлен"
    notes: str | None = None


class BookingCreate(BookingBase):
    """total_cost НЕ передаётся клиентом — рассчитывается на бэкенде."""

    pass


class BookingUpdate(BookingBase):
    pass


class ClientBookingCreate(BaseModel):
    """Заявка, которую клиент оформляет сам с витрины.

    Ни client_id, ни скидку/комиссию, ни статус клиент задать не может —
    всё это выставляет бэкенд в routers/bookings.py::create_self_booking.
    """

    tour_id: int
    people_count: int = Field(gt=0)
    notes: str | None = None


class BookingStatusUpdate(BaseModel):
    status: BookingStatus


class BookingRead(BookingBase):
    model_config = ConfigDict(from_attributes=True)
    booking_id: int
    booking_date: date
    total_cost: Decimal
    # Денормализация из связей — чтобы список бронирований показывал
    # «Иванов Иван · Турция, Анталия», а не «Клиент #17 · Тур #5».
    # Заполняются свойствами модели Booking; None, если связь не подгружена.
    client_name: str | None = None
    tour_name: str | None = None
    tour_country: str | None = None
    tour_city: str | None = None
    tour_start_date: date | None = None
    tour_end_date: date | None = None


class BookingBalance(BaseModel):
    """Остаток к оплате по бронированию."""

    booking_id: int
    total_cost: Decimal
    paid_amount: Decimal
    remaining: Decimal
    is_paid: bool
