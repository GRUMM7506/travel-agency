from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentActor, get_current_actor, get_current_client, get_current_staff
from app.core.config import settings
from app.core.database import get_db
from app.crud import booking as crud
from app.models.client import Client
from app.schemas.booking import (
    CLIENT_ALLOWED_STATUSES,
    BookingBalance,
    BookingCreate,
    BookingRead,
    BookingStatusUpdate,
    BookingUpdate,
    ClientBookingCreate,
)
from app.schemas.payment import PaymentRequisites
from app.services import booking_service, payment_service

router = APIRouter(prefix="/bookings", tags=["Bookings"])
# ПРИМЕЧАНИЕ: защита здесь навешана поштучно на каждый эндпоинт (а не через
# dependencies=[...] в APIRouter), т.к. в этом роутере соседствуют три вида
# доступа: только сотрудник, только клиент (/self, /my) и оба сразу
# (/balance, /status) — общая зависимость на уровне роутера сломала бы два из трёх.


# ---------------------------------------------------------------------------
# Клиентские маршруты. Объявлены ВЫШЕ /{booking_id}, иначе FastAPI попытается
# разобрать "my" как booking_id и вернёт 422.
# ---------------------------------------------------------------------------


@router.get("/my", response_model=list[BookingRead])
async def my_bookings(
    current_client: Client = Depends(get_current_client),
    db: AsyncSession = Depends(get_db),
):
    return await crud.get_all(db, client_id=current_client.client_id)


@router.post("/self", response_model=BookingRead, status_code=status.HTTP_201_CREATED)
async def create_self_booking(
    data: ClientBookingCreate,
    current_client: Client = Depends(get_current_client),
    db: AsyncSession = Depends(get_db),
):
    """Заявка от клиента с витрины.

    Клиент не управляет ни скидкой, ни комиссией, ни статусом: скидка 0,
    комиссия — агентская по умолчанию, статус «ожидает оплаты». Дальше
    сотрудник вручную подтверждает платёж и двигает статус.
    """
    booking = await booking_service.build_booking(
        db,
        BookingCreate(
            client_id=current_client.client_id,
            tour_id=data.tour_id,
            people_count=data.people_count,
            discount_percent=Decimal("0"),
            commission_percent=settings.DEFAULT_COMMISSION_PERCENT,
            status="ожидает оплаты",
            notes=data.notes,
        ),
    )
    return await crud.create(db, booking)


@router.get("/requisites", response_model=PaymentRequisites)
async def payment_requisites(_: CurrentActor = Depends(get_current_actor)):
    """Реквизиты для перевода — клиент платит вручную, сотрудник подтверждает.

    Берутся из настроек (.env), а не хардкодятся в виджете.
    """
    return PaymentRequisites(
        recipient=settings.PAYMENT_RECIPIENT,
        card_number=settings.PAYMENT_CARD_NUMBER,
        bank_name=settings.PAYMENT_BANK_NAME,
        comment=settings.PAYMENT_COMMENT,
    )


# ---------------------------------------------------------------------------
# Маршруты сотрудника
# ---------------------------------------------------------------------------


@router.get("", response_model=list[BookingRead], dependencies=[Depends(get_current_staff)])
async def list_bookings(
    client_id: int | None = Query(None),
    booking_status: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
):
    return await crud.get_all(db, client_id=client_id, status=booking_status)


@router.get(
    "/{booking_id}", response_model=BookingRead, dependencies=[Depends(get_current_staff)]
)
async def get_booking(booking_id: int, db: AsyncSession = Depends(get_db)):
    booking = await crud.get_by_id(db, booking_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Бронирование не найдено")
    return booking


@router.post(
    "",
    response_model=BookingRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(get_current_staff)],
)
async def create_booking(data: BookingCreate, db: AsyncSession = Depends(get_db)):
    booking = await booking_service.build_booking(db, data)
    return await crud.create(db, booking)


@router.put(
    "/{booking_id}", response_model=BookingRead, dependencies=[Depends(get_current_staff)]
)
async def update_booking(booking_id: int, data: BookingUpdate, db: AsyncSession = Depends(get_db)):
    booking = await crud.get_by_id(db, booking_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Бронирование не найдено")
    total_cost = await booking_service.recalc_total_cost(
        db, data.tour_id, data.people_count, data.discount_percent
    )
    return await crud.update(db, booking, data, total_cost)


@router.delete(
    "/{booking_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(get_current_staff)],
)
async def delete_booking(booking_id: int, db: AsyncSession = Depends(get_db)):
    booking = await crud.get_by_id(db, booking_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Бронирование не найдено")
    await crud.delete(db, booking)


# ---------------------------------------------------------------------------
# Общие маршруты: доступны и сотруднику, и владельцу брони
# ---------------------------------------------------------------------------


async def _booking_for_actor(db: AsyncSession, booking_id: int, actor: CurrentActor):
    """Достаёт бронирование и проверяет, что actor имеет к нему отношение."""
    booking = await crud.get_by_id(db, booking_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Бронирование не найдено")
    if not actor.owns(booking.client_id):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, detail="Это бронирование принадлежит другому клиенту"
        )
    return booking


@router.get("/{booking_id}/balance", response_model=BookingBalance)
async def booking_balance(
    booking_id: int,
    actor: CurrentActor = Depends(get_current_actor),
    db: AsyncSession = Depends(get_db),
):
    await _booking_for_actor(db, booking_id, actor)
    return await payment_service.get_balance(db, booking_id)


@router.patch("/{booking_id}/status", response_model=BookingRead)
async def update_booking_status(
    booking_id: int,
    data: BookingStatusUpdate,
    actor: CurrentActor = Depends(get_current_actor),
    db: AsyncSession = Depends(get_db),
):
    """Сотрудник ставит любой статус; клиент — только «на проверке» (я оплатил)
    или «отменён», и только своей брони."""
    booking = await _booking_for_actor(db, booking_id, actor)

    if not actor.is_staff and data.status not in CLIENT_ALLOWED_STATUSES:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail="Клиент может только сообщить об оплате или отменить заявку",
        )

    return await crud.set_status(db, booking, data.status)
