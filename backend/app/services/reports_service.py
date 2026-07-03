from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.booking import Booking
from app.models.carrier import Carrier
from app.models.client import Client
from app.models.hotel import Hotel
from app.models.payment import Payment
from app.models.tour import Tour
from app.schemas.report import (
    AgencyRevenueRow,
    DashboardStats,
    MonthlyRevenueRow,
    PopularDestinationRow,
    SalesReportRow,
)


async def sales_report(db: AsyncSession, date_from: date, date_to: date) -> list[SalesReportRow]:
    stmt = (
        select(
            Booking.booking_id,
            Booking.booking_date,
            (Client.last_name + " " + Client.first_name).label("client_name"),
            Tour.tour_name,
            Booking.people_count,
            Booking.total_cost,
            Booking.status,
        )
        .join(Client, Booking.client_id == Client.client_id)
        .join(Tour, Booking.tour_id == Tour.tour_id)
        .where(Booking.booking_date.between(date_from, date_to))
        .order_by(Booking.booking_date.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()
    return [
        SalesReportRow(
            booking_id=r.booking_id,
            booking_date=r.booking_date,
            client_name=r.client_name,
            tour_name=r.tour_name,
            people_count=r.people_count,
            total_cost=r.total_cost,
            status=r.status,
        )
        for r in rows
    ]


async def popular_destinations(db: AsyncSession) -> list[PopularDestinationRow]:
    stmt = (
        select(
            Tour.country,
            Tour.city,
            func.count(Booking.booking_id).label("bookings_count"),
            func.coalesce(func.sum(Booking.people_count), 0).label("total_people"),
        )
        .join(Booking, Booking.tour_id == Tour.tour_id)
        .group_by(Tour.country, Tour.city)
        .order_by(func.count(Booking.booking_id).desc())
    )
    result = await db.execute(stmt)
    rows = result.all()
    return [
        PopularDestinationRow(
            country=r.country, city=r.city, bookings_count=r.bookings_count, total_people=r.total_people
        )
        for r in rows
    ]


async def agency_revenue(db: AsyncSession, date_from: date, date_to: date) -> AgencyRevenueRow:
    stmt = select(
        func.coalesce(
            func.sum(Booking.total_cost * Booking.commission_percent / 100), 0
        ).label("total_commission"),
        func.count(Booking.booking_id).label("bookings_count"),
    ).where(Booking.booking_date.between(date_from, date_to))
    result = await db.execute(stmt)
    row = result.one()
    return AgencyRevenueRow(
        period=f"{date_from} — {date_to}",
        total_commission=row.total_commission,
        bookings_count=row.bookings_count,
    )


async def monthly_revenue(db: AsyncSession, months: int = 12) -> list[MonthlyRevenueRow]:
    """Комиссия по месяцам за последние `months` месяцев — данные для графика.

    Отменённые брони в выручку не идут: агентство с них ничего не получает.
    """
    month_col = func.to_char(Booking.booking_date, "YYYY-MM").label("month")
    stmt = (
        select(
            month_col,
            func.coalesce(
                func.sum(Booking.total_cost * Booking.commission_percent / 100), 0
            ).label("total_commission"),
            func.count(Booking.booking_id).label("bookings_count"),
        )
        .where(Booking.status != "отменён")
        .group_by(month_col)
        .order_by(month_col.desc())
        .limit(months)
    )
    result = await db.execute(stmt)
    rows = list(result.all())
    rows.reverse()  # график читается слева направо, от старого к новому
    return [
        MonthlyRevenueRow(
            month=r.month,
            total_commission=r.total_commission,
            bookings_count=r.bookings_count,
        )
        for r in rows
    ]


async def dashboard_stats(db: AsyncSession) -> DashboardStats:
    """Одним запросом-пакетом собирает сводку для главного экрана админки."""
    today = date.today()

    async def _scalar(stmt) -> Decimal | int:
        result = await db.execute(stmt)
        return result.scalar_one()

    tours_count = await _scalar(select(func.count(Tour.tour_id)))
    active_tours_count = await _scalar(
        select(func.count(Tour.tour_id)).where(Tour.end_date >= today)
    )
    clients_count = await _scalar(select(func.count(Client.client_id)))
    bookings_count = await _scalar(select(func.count(Booking.booking_id)))
    hotels_count = await _scalar(select(func.count(Hotel.hotel_id)))
    carriers_count = await _scalar(select(func.count(Carrier.carrier_id)))

    # Отменённые брони не считаем ни выручкой, ни долгом.
    active_bookings = Booking.status != "отменён"
    total_revenue = Decimal(
        await _scalar(
            select(func.coalesce(func.sum(Booking.total_cost), 0)).where(active_bookings)
        )
    )
    total_commission = Decimal(
        await _scalar(
            select(
                func.coalesce(
                    func.sum(Booking.total_cost * Booking.commission_percent / 100), 0
                )
            ).where(active_bookings)
        )
    )
    paid = Decimal(
        await _scalar(
            select(func.coalesce(func.sum(Payment.amount), 0))
            .join(Booking, Payment.booking_id == Booking.booking_id)
            .where(active_bookings)
        )
    )

    status_rows = await db.execute(
        select(Booking.status, func.count(Booking.booking_id)).group_by(Booking.status)
    )

    return DashboardStats(
        tours_count=tours_count,
        active_tours_count=active_tours_count,
        clients_count=clients_count,
        bookings_count=bookings_count,
        hotels_count=hotels_count,
        carriers_count=carriers_count,
        total_revenue=total_revenue,
        total_commission=total_commission,
        paid_amount=paid,
        outstanding_amount=max(total_revenue - paid, Decimal("0")),
        bookings_by_status={status: count for status, count in status_rows.all()},
    )
