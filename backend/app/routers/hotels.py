from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.crud import hotel as crud
from app.schemas.hotel import HotelCreate, HotelRead, HotelUpdate

router = APIRouter(prefix="/hotels", tags=["Hotels"], dependencies=[Depends(get_current_staff)])


@router.get("", response_model=list[HotelRead])
async def list_hotels(db: AsyncSession = Depends(get_db)):
    return await crud.get_all(db)


@router.get("/{hotel_id}", response_model=HotelRead)
async def get_hotel(hotel_id: int, db: AsyncSession = Depends(get_db)):
    hotel = await crud.get_by_id(db, hotel_id)
    if hotel is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Отель не найден")
    return hotel


@router.post("", response_model=HotelRead, status_code=status.HTTP_201_CREATED)
async def create_hotel(data: HotelCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create(db, data)


@router.put("/{hotel_id}", response_model=HotelRead)
async def update_hotel(hotel_id: int, data: HotelUpdate, db: AsyncSession = Depends(get_db)):
    hotel = await crud.get_by_id(db, hotel_id)
    if hotel is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Отель не найден")
    return await crud.update(db, hotel, data)


@router.delete("/{hotel_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_hotel(hotel_id: int, db: AsyncSession = Depends(get_db)):
    hotel = await crud.get_by_id(db, hotel_id)
    if hotel is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Отель не найден")
    await crud.delete(db, hotel)
