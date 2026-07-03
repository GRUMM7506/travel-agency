import asyncio
import sys

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# На Windows дефолтный ProactorEventLoop не поддерживает async-режим psycopg3.
# Переключаемся на SelectorEventLoop — иначе uvicorn падает с psycopg.InterfaceError.
# Должно быть выполнено до первого создания event loop (т.е. до запуска uvicorn/asyncio.run).
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# psycopg3 async driver -> "postgresql+psycopg://..."
engine = create_async_engine(settings.DATABASE_URL, echo=False, future=True)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
