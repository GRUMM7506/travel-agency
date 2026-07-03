from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.hotel import Hotel
from app.schemas.hotel import HotelCreate, HotelUpdate


async def get_all(db: AsyncSession) -> list[Hotel]:
    result = await db.execute(select(Hotel).order_by(Hotel.hotel_name))
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, hotel_id: int) -> Hotel | None:
    return await db.get(Hotel, hotel_id)


async def create(db: AsyncSession, data: HotelCreate) -> Hotel:
    hotel = Hotel(**data.model_dump())
    db.add(hotel)
    await db.commit()
    await db.refresh(hotel)
    return hotel


async def update(db: AsyncSession, hotel: Hotel, data: HotelUpdate) -> Hotel:
    for field, value in data.model_dump().items():
        setattr(hotel, field, value)
    await db.commit()
    await db.refresh(hotel)
    return hotel


async def delete(db: AsyncSession, hotel: Hotel) -> None:
    await db.delete(hotel)
    await db.commit()
