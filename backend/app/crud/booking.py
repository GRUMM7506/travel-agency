from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.booking import Booking
from app.schemas.booking import BookingUpdate


async def get_all(
    db: AsyncSession,
    client_id: int | None = None,
    status: str | None = None,
) -> list[Booking]:
    stmt = (
        select(Booking)
        .options(selectinload(Booking.client), selectinload(Booking.tour))
        .order_by(Booking.booking_date.desc(), Booking.booking_id.desc())
    )
    if client_id is not None:
        stmt = stmt.where(Booking.client_id == client_id)
    if status is not None:
        stmt = stmt.where(Booking.status == status)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, booking_id: int) -> Booking | None:
    stmt = (
        select(Booking)
        .options(selectinload(Booking.client), selectinload(Booking.tour))
        .where(Booking.booking_id == booking_id)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def create(db: AsyncSession, booking: Booking) -> Booking:
    """Принимает уже собранный объект Booking — total_cost считается в services/booking_service.py."""
    db.add(booking)
    await db.commit()
    # Перечитываем через get_by_id, а не refresh: ответу нужны client/tour,
    # иначе денормализованные поля BookingRead уедут в null.
    return await get_by_id(db, booking.booking_id)


async def update(db: AsyncSession, booking: Booking, data: BookingUpdate, total_cost) -> Booking:
    for field, value in data.model_dump(exclude={"booking_date"}).items():
        setattr(booking, field, value)
    booking.total_cost = total_cost
    await db.commit()
    await db.refresh(booking, ["client", "tour"])
    return booking


async def set_status(db: AsyncSession, booking: Booking, status: str) -> Booking:
    booking.status = status
    await db.commit()
    await db.refresh(booking, ["client", "tour"])
    return booking


async def delete(db: AsyncSession, booking: Booking) -> None:
    await db.delete(booking)
    await db.commit()
