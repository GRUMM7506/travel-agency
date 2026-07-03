"""Создаёт первого администратора.

Запуск (из корня backend, с активным venv):

    ADMIN_EMAIL=admin@agency.local ADMIN_PASSWORD=secret123 ADMIN_FULL_NAME="Админ Админов" \\
        python -m app.scripts.create_admin

Если ADMIN_EMAIL/ADMIN_PASSWORD не заданы — скрипт ничего не создаёт и просто
печатает подсказку. Если сотрудник с таким email уже есть — тоже ничего не делает.
"""
import asyncio
import os

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.core.security import hash_password
from app.models.staff import Staff


async def main() -> None:
    email = os.getenv("ADMIN_EMAIL")
    password = os.getenv("ADMIN_PASSWORD")
    full_name = os.getenv("ADMIN_FULL_NAME", "Администратор")

    if not email or not password:
        print(
            "Не заданы ADMIN_EMAIL и/или ADMIN_PASSWORD.\n"
            "Пример запуска:\n"
            '  ADMIN_EMAIL=admin@agency.local ADMIN_PASSWORD=secret123 '
            "python -m app.scripts.create_admin"
        )
        return

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Staff).where(Staff.email == email))
        existing = result.scalar_one_or_none()
        if existing is not None:
            print(f"Сотрудник с email={email} уже существует (staff_id={existing.staff_id}).")
            return

        admin = Staff(
            full_name=full_name,
            email=email,
            password_hash=hash_password(password),
            role="admin",
            is_active=True,
        )
        db.add(admin)
        await db.commit()
        await db.refresh(admin)
        print(f"Создан администратор: staff_id={admin.staff_id}, email={admin.email}")


if __name__ == "__main__":
    asyncio.run(main())
