from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class SalesReportRow(BaseModel):
    booking_id: int
    booking_date: date
    client_name: str
    tour_name: str
    people_count: int
    total_cost: Decimal
    status: str


class PopularDestinationRow(BaseModel):
    country: str
    city: str
    bookings_count: int
    total_people: int


class AgencyRevenueRow(BaseModel):
    period: str
    total_commission: Decimal
    bookings_count: int


class MonthlyRevenueRow(BaseModel):
    """Комиссия по месяцам — для графика на экране отчётов."""

    month: str  # "2026-08"
    total_commission: Decimal
    bookings_count: int


class DashboardStats(BaseModel):
    """Сводка для главного экрана админки — вместо захардкоженных «15+/500+»."""

    tours_count: int
    active_tours_count: int
    clients_count: int
    bookings_count: int
    hotels_count: int
    carriers_count: int
    total_revenue: Decimal
    total_commission: Decimal
    paid_amount: Decimal
    outstanding_amount: Decimal
    bookings_by_status: dict[str, int]
