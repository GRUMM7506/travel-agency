from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.client import Client
from app.schemas.client import ClientCreate, ClientUpdate


async def get_all(db: AsyncSession) -> list[Client]:
    result = await db.execute(select(Client).order_by(Client.last_name))
    return list(result.scalars().all())


async def get_by_id(db: AsyncSession, client_id: int) -> Client | None:
    return await db.get(Client, client_id)


async def search(db: AsyncSession, query: str) -> list[Client]:
    pattern = f"%{query}%"
    stmt = select(Client).where(
        or_(
            Client.last_name.ilike(pattern),
            Client.first_name.ilike(pattern),
            Client.phone.ilike(pattern),
            Client.email.ilike(pattern),
        )
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create(db: AsyncSession, data: ClientCreate) -> Client:
    client = Client(**data.model_dump())
    db.add(client)
    await db.commit()
    await db.refresh(client)
    return client


async def update(db: AsyncSession, client: Client, data: ClientUpdate) -> Client:
    for field, value in data.model_dump().items():
        setattr(client, field, value)
    await db.commit()
    await db.refresh(client)
    return client


async def delete(db: AsyncSession, client: Client) -> None:
    await db.delete(client)
    await db.commit()
