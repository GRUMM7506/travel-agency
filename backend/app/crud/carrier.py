from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.carrier import Carrier
from app.schemas.carrier import CarrierCreate, CarrierUpdate


async def get_all(db: AsyncSession) -> list[Carrier]:
    result = await db.execute(select(Carrier).order_by(Carrier.company_name))
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, carrier_id: int) -> Carrier | None:
    return await db.get(Carrier, carrier_id)


async def create(db: AsyncSession, data: CarrierCreate) -> Carrier:
    carrier = Carrier(**data.model_dump())
    db.add(carrier)
    await db.commit()
    await db.refresh(carrier)
    return carrier


async def update(db: AsyncSession, carrier: Carrier, data: CarrierUpdate) -> Carrier:
    for field, value in data.model_dump().items():
        setattr(carrier, field, value)
    await db.commit()
    await db.refresh(carrier)
    return carrier


async def delete(db: AsyncSession, carrier: Carrier) -> None:
    await db.delete(carrier)
    await db.commit()
