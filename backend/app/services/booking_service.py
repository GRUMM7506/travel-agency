from datetime import date
from decimal import ROUND_HALF_UP, Decimal

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.crud import tour as tour_crud
from app.models.booking import Booking
from app.schemas.booking import BookingCreate


def calc_total_cost(base_price: Decimal, people_count: int, discount_percent: Decimal) -> Decimal:
    """total_cost = base_price * people_count * (1 - discount/100), округление до копеек."""
    raw = base_price * people_count * (1 - discount_percent / Decimal("100"))
    return raw.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def calc_commission(total_cost: Decimal, commission_percent: Decimal) -> Decimal:
    raw = total_cost * commission_percent / Decimal("100")
    return raw.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


async def build_booking(db: AsyncSession, data: BookingCreate) -> Booking:
    """Проверяет тур, считает total_cost и собирает объект Booking (ещё не сохранён)."""
    tour = await tour_crud.get_by_id(db, data.tour_id)
    if tour is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Тур не найден")

    total_cost = calc_total_cost(tour.base_price, data.people_count, data.discount_percent)

    return Booking(
        client_id=data.client_id,
        tour_id=data.tour_id,
        booking_date=data.booking_date or date.today(),
        people_count=data.people_count,
        discount_percent=data.discount_percent,
        commission_percent=data.commission_percent,
        total_cost=total_cost,
        status=data.status,
        notes=data.notes,
    )


async def recalc_total_cost(db: AsyncSession, tour_id: int, people_count: int, discount_percent: Decimal) -> Decimal:
    tour = await tour_crud.get_by_id(db, tour_id)
    if tour is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Тур не найден")
    return calc_total_cost(tour.base_price, people_count, discount_percent)
