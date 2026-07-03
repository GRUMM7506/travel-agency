from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.crud import payment as crud
from app.schemas.payment import PaymentCreate, PaymentRead, PaymentUpdate

router = APIRouter(prefix="/payments", tags=["Payments"], dependencies=[Depends(get_current_staff)])


@router.get("", response_model=list[PaymentRead])
async def list_payments(booking_id: int | None = Query(None), db: AsyncSession = Depends(get_db)):
    return await crud.get_all(db, booking_id=booking_id)


@router.get("/{payment_id}", response_model=PaymentRead)
async def get_payment(payment_id: int, db: AsyncSession = Depends(get_db)):
    payment = await crud.get_by_id(db, payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Платёж не найден")
    return payment


@router.post("", response_model=PaymentRead, status_code=status.HTTP_201_CREATED)
async def create_payment(data: PaymentCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create(db, data)


@router.put("/{payment_id}", response_model=PaymentRead)
async def update_payment(payment_id: int, data: PaymentUpdate, db: AsyncSession = Depends(get_db)):
    payment = await crud.get_by_id(db, payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Платёж не найден")
    return await crud.update(db, payment, data)


@router.delete("/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payment(payment_id: int, db: AsyncSession = Depends(get_db)):
    payment = await crud.get_by_id(db, payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Платёж не найден")
    await crud.delete(db, payment)
