from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.crud import client as crud
from app.schemas.client import ClientCreate, ClientRead, ClientUpdate

router = APIRouter(prefix="/clients", tags=["Clients"], dependencies=[Depends(get_current_staff)])


@router.get("", response_model=list[ClientRead])
async def list_clients(db: AsyncSession = Depends(get_db)):
    return await crud.get_all(db)


@router.get("/search", response_model=list[ClientRead])
async def search_clients(q: str = Query(..., min_length=1), db: AsyncSession = Depends(get_db)):
    return await crud.search(db, q)


@router.get("/{client_id}", response_model=ClientRead)
async def get_client(client_id: int, db: AsyncSession = Depends(get_db)):
    client = await crud.get_by_id(db, client_id)
    if client is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Клиент не найден")
    return client


@router.post("", response_model=ClientRead, status_code=status.HTTP_201_CREATED)
async def create_client(data: ClientCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create(db, data)


@router.put("/{client_id}", response_model=ClientRead)
async def update_client(client_id: int, data: ClientUpdate, db: AsyncSession = Depends(get_db)):
    client = await crud.get_by_id(db, client_id)
    if client is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Клиент не найден")
    return await crud.update(db, client, data)


@router.delete("/{client_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_client(client_id: int, db: AsyncSession = Depends(get_db)):
    client = await crud.get_by_id(db, client_id)
    if client is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Клиент не найден")
    await crud.delete(db, client)
