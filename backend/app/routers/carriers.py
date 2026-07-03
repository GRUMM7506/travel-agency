from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.crud import carrier as crud
from app.schemas.carrier import CarrierCreate, CarrierRead, CarrierUpdate

router = APIRouter(prefix="/carriers", tags=["Carriers"], dependencies=[Depends(get_current_staff)])


@router.get("", response_model=list[CarrierRead])
async def list_carriers(db: AsyncSession = Depends(get_db)):
    return await crud.get_all(db)


@router.get("/{carrier_id}", response_model=CarrierRead)
async def get_carrier(carrier_id: int, db: AsyncSession = Depends(get_db)):
    carrier = await crud.get_by_id(db, carrier_id)
    if carrier is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Перевозчик не найден")
    return carrier


@router.post("", response_model=CarrierRead, status_code=status.HTTP_201_CREATED)
async def create_carrier(data: CarrierCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create(db, data)


@router.put("/{carrier_id}", response_model=CarrierRead)
async def update_carrier(carrier_id: int, data: CarrierUpdate, db: AsyncSession = Depends(get_db)):
    carrier = await crud.get_by_id(db, carrier_id)
    if carrier is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Перевозчик не найден")
    return await crud.update(db, carrier, data)


@router.delete("/{carrier_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_carrier(carrier_id: int, db: AsyncSession = Depends(get_db)):
    carrier = await crud.get_by_id(db, carrier_id)
    if carrier is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Перевозчик не найден")
    await crud.delete(db, carrier)
