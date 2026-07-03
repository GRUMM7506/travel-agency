from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin
from app.core.database import get_db
from app.core.security import hash_password
from app.models.staff import Staff
from app.schemas.auth import StaffCreate, StaffRead, StaffUpdate

router = APIRouter(prefix="/staff", tags=["Staff"], dependencies=[Depends(get_current_admin)])

_email_taken = HTTPException(
    status.HTTP_409_CONFLICT, detail="Сотрудник с таким email уже существует"
)


async def _get_or_404(db: AsyncSession, staff_id: int) -> Staff:
    staff = await db.get(Staff, staff_id)
    if staff is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Сотрудник не найден")
    return staff


async def _email_exists(db: AsyncSession, email: str, exclude_id: int | None = None) -> bool:
    stmt = select(Staff.staff_id).where(Staff.email == email)
    if exclude_id is not None:
        stmt = stmt.where(Staff.staff_id != exclude_id)
    result = await db.execute(stmt)
    return result.first() is not None


@router.get("", response_model=list[StaffRead])
async def list_staff(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Staff).order_by(Staff.full_name))
    return list(result.scalars().all())


@router.post("", response_model=StaffRead, status_code=status.HTTP_201_CREATED)
async def create_staff(data: StaffCreate, db: AsyncSession = Depends(get_db)):
    if await _email_exists(db, data.email):
        raise _email_taken

    staff = Staff(
        full_name=data.full_name,
        email=data.email,
        password_hash=hash_password(data.password),
        role=data.role,
        is_active=data.is_active,
    )
    db.add(staff)
    await db.commit()
    await db.refresh(staff)
    return staff


@router.put("/{staff_id}", response_model=StaffRead)
async def update_staff(
    staff_id: int,
    data: StaffUpdate,
    current_admin: Staff = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    staff = await _get_or_404(db, staff_id)

    if await _email_exists(db, data.email, exclude_id=staff_id):
        raise _email_taken

    # Защита от «выстрела в ногу»: админ не может разжаловать или отключить
    # сам себя — иначе система рискует остаться вообще без администратора.
    if staff.staff_id == current_admin.staff_id and (
        data.role != "admin" or not data.is_active
    ):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="Нельзя снять с себя роль администратора или отключить свою учётную запись",
        )

    staff.full_name = data.full_name
    staff.email = data.email
    staff.role = data.role
    staff.is_active = data.is_active
    if data.password:
        staff.password_hash = hash_password(data.password)

    await db.commit()
    await db.refresh(staff)
    return staff


@router.delete("/{staff_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_staff(
    staff_id: int,
    current_admin: Staff = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    if staff_id == current_admin.staff_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Нельзя удалить собственную учётную запись"
        )
    staff = await _get_or_404(db, staff_id)
    await db.delete(staff)
    await db.commit()
