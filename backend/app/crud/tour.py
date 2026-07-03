from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.tour import Tour
from app.schemas.tour import TourCreate, TourUpdate


async def get_all(
    db: AsyncSession,
    country: str | None = None,
    price_min: Decimal | None = None,
    price_max: Decimal | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    only_upcoming: bool = False,
) -> list[Tour]:
    stmt = select(Tour).options(selectinload(Tour.hotel), selectinload(Tour.carrier))

    # Витрина показывает только то, что ещё можно купить. Сотруднику в админке,
    # наоборот, нужен полный список вместе с архивом — поэтому не режем всегда,
    # а только по явному запросу.
    if only_upcoming:
        stmt = stmt.where(Tour.end_date >= date.today())
    if country:
        stmt = stmt.where(Tour.country.ilike(f"%{country}%"))
    if price_min is not None:
        stmt = stmt.where(Tour.base_price >= price_min)
    if price_max is not None:
        stmt = stmt.where(Tour.base_price <= price_max)
    if date_from is not None:
        stmt = stmt.where(Tour.start_date >= date_from)
    if date_to is not None:
        stmt = stmt.where(Tour.end_date <= date_to)

    stmt = stmt.order_by(Tour.start_date)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, tour_id: int) -> Tour | None:
    stmt = (
        select(Tour)
        .options(selectinload(Tour.hotel), selectinload(Tour.carrier))
        .where(Tour.tour_id == tour_id)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def search(db: AsyncSession, query: str) -> list[Tour]:
    pattern = f"%{query}%"
    stmt = (
        select(Tour)
        .options(selectinload(Tour.hotel), selectinload(Tour.carrier))
        .where(
            Tour.tour_name.ilike(pattern)
            | Tour.country.ilike(pattern)
            | Tour.city.ilike(pattern)
        )
        .order_by(Tour.start_date)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create(db: AsyncSession, data: TourCreate) -> Tour:
    tour = Tour(**data.model_dump())
    db.add(tour)
    await db.commit()
    # Перечитываем со связями — ответу нужны hotel_name/carrier_name.
    return await get_by_id(db, tour.tour_id)


async def update(db: AsyncSession, tour: Tour, data: TourUpdate) -> Tour:
    for field, value in data.model_dump().items():
        setattr(tour, field, value)
    await db.commit()
    # duration_days — generated column, пересчитывается в БД при смене дат,
    # поэтому его тоже нужно перечитать.
    await db.refresh(tour, ["hotel", "carrier", "duration_days"])
    return tour


async def delete(db: AsyncSession, tour: Tour) -> None:
    await db.delete(tour)
    await db.commit()
