from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.booking import Booking
from app.models.payment import Payment
from app.schemas.booking import BookingBalance

_ZERO = Decimal("0.00")


async def paid_amount(db: AsyncSession, booking_id: int) -> Decimal:
    """Сумма всех платежей по бронированию (0, если платежей нет)."""
    stmt = select(func.coalesce(func.sum(Payment.amount), 0)).where(
        Payment.booking_id == booking_id
    )
    result = await db.execute(stmt)
    return Decimal(result.scalar_one()).quantize(Decimal("0.01"))


async def get_balance(db: AsyncSession, booking_id: int) -> BookingBalance:
    """Остаток к оплате: total_cost − сумма платежей.

    remaining не уходит ниже нуля: переплату показываем как «оплачено полностью»,
    отрицательный долг на экране только путал бы сотрудника.
    """
    booking = await db.get(Booking, booking_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Бронирование не найдено")

    paid = await paid_amount(db, booking_id)
    total = Decimal(booking.total_cost).quantize(Decimal("0.01"))
    remaining = max(total - paid, _ZERO)

    return BookingBalance(
        booking_id=booking_id,
        total_cost=total,
        paid_amount=paid,
        remaining=remaining,
        is_paid=remaining == _ZERO,
    )
