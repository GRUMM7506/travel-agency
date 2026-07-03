from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.crud import tour as crud
from app.schemas.tour import TourCreate, TourReadWithRelations, TourUpdate

router = APIRouter(prefix="/tours", tags=["Tours"])
# ВАЖНО: список/поиск/детали тура остаются публичными — их читает витрина
# client_mode_screen.dart БЕЗ логина. Защищены только create/update/delete.


@router.get("", response_model=list[TourReadWithRelations])
async def list_tours(
    country: str | None = Query(None),
    price_min: Decimal | None = Query(None),
    price_max: Decimal | None = Query(None),
    date_from: date | None = Query(None),
    date_to: date | None = Query(None),
    only_upcoming: bool = Query(
        False, description="Только туры, которые ещё не завершились — для витрины"
    ),
    db: AsyncSession = Depends(get_db),
):
    return await crud.get_all(
        db,
        country=country,
        price_min=price_min,
        price_max=price_max,
        date_from=date_from,
        date_to=date_to,
        only_upcoming=only_upcoming,
    )


@router.get("/search", response_model=list[TourReadWithRelations])
async def search_tours(q: str = Query(..., min_length=1), db: AsyncSession = Depends(get_db)):
    return await crud.search(db, q)


@router.get("/{tour_id}", response_model=TourReadWithRelations)
async def get_tour(tour_id: int, db: AsyncSession = Depends(get_db)):
    tour = await crud.get_by_id(db, tour_id)
    if tour is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Тур не найден")
    return tour


@router.post(
    "",
    response_model=TourReadWithRelations,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(get_current_staff)],
)
async def create_tour(data: TourCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create(db, data)


@router.put(
    "/{tour_id}", response_model=TourReadWithRelations, dependencies=[Depends(get_current_staff)]
)
async def update_tour(tour_id: int, data: TourUpdate, db: AsyncSession = Depends(get_db)):
    tour = await crud.get_by_id(db, tour_id)
    if tour is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Тур не найден")
    return await crud.update(db, tour, data)


@router.delete(
    "/{tour_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(get_current_staff)],
)
async def delete_tour(tour_id: int, db: AsyncSession = Depends(get_db)):
    tour = await crud.get_by_id(db, tour_id)
    if tour is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Тур не найден")
    await crud.delete(db, tour)
