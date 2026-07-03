from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment import Payment
from app.schemas.payment import PaymentCreate, PaymentUpdate


async def get_all(db: AsyncSession, booking_id: int | None = None) -> list[Payment]:
    stmt = select(Payment).order_by(Payment.payment_date.desc())
    if booking_id is not None:
        stmt = stmt.where(Payment.booking_id == booking_id)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, payment_id: int) -> Payment | None:
    return await db.get(Payment, payment_id)


async def create(db: AsyncSession, data: PaymentCreate) -> Payment:
    payment = Payment(**data.model_dump())
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment


async def update(db: AsyncSession, payment: Payment, data: PaymentUpdate) -> Payment:
    for field, value in data.model_dump().items():
        setattr(payment, field, value)
    await db.commit()
    await db.refresh(payment)
    return payment


async def delete(db: AsyncSession, payment: Payment) -> None:
    await db.delete(payment)
    await db.commit()
