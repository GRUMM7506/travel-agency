from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.booking import Booking
from app.models.payment import Payment
from app.schemas.booking import BookingBalance
from app.schemas.payment import CheckoutRequest, CheckoutResult, PaymentRead

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


async def checkout(db: AsyncSession, booking: Booking, data: CheckoutRequest) -> CheckoutResult:
    """Демо-оплата картой: закрывает остаток по брони одним платежом.

    Шлюза нет — «проведение» имитируется на клиенте. Здесь происходит всё,
    что имеет значение для учёта: платёж на остаток попадает в payments,
    а бронь сразу переходит в «оплачен», без ручного подтверждения
    сотрудником (в отличие от перевода по реквизитам, который был раньше).
    """
    if booking.status == "отменён":
        raise HTTPException(
            status.HTTP_409_CONFLICT, detail="Бронирование отменено — оплата невозможна"
        )

    balance = await get_balance(db, booking.booking_id)
    if balance.is_paid:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="Бронирование уже оплачено")

    payment = Payment(
        booking_id=booking.booking_id,
        amount=balance.remaining,
        # payment_date не задаём: в БД у колонки server_default = CURRENT_DATE.
        payment_method=f"карта ****{data.card_last4}",
        notes="Онлайн-оплата (демонстрационный шлюз)",
    )
    db.add(payment)
    booking.status = "оплачен"
    await db.commit()
    await db.refresh(payment)

    return CheckoutResult(
        payment=PaymentRead.model_validate(payment),
        balance=await get_balance(db, booking.booking_id),
        booking_status=booking.status,
    )
