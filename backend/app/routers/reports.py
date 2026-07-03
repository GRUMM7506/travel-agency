from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_staff
from app.core.database import get_db
from app.schemas.report import (
    AgencyRevenueRow,
    DashboardStats,
    MonthlyRevenueRow,
    PopularDestinationRow,
    SalesReportRow,
)
from app.services import reports_service

router = APIRouter(prefix="/reports", tags=["Reports"], dependencies=[Depends(get_current_staff)])


@router.get("/dashboard", response_model=DashboardStats)
async def dashboard(db: AsyncSession = Depends(get_db)):
    return await reports_service.dashboard_stats(db)


@router.get("/monthly-revenue", response_model=list[MonthlyRevenueRow])
async def monthly_revenue(
    months: int = Query(12, ge=1, le=36), db: AsyncSession = Depends(get_db)
):
    return await reports_service.monthly_revenue(db, months)


@router.get("/sales", response_model=list[SalesReportRow])
async def sales_report(
    date_from: date = Query(...), date_to: date = Query(...), db: AsyncSession = Depends(get_db)
):
    return await reports_service.sales_report(db, date_from, date_to)


@router.get("/popular-destinations", response_model=list[PopularDestinationRow])
async def popular_destinations(db: AsyncSession = Depends(get_db)):
    return await reports_service.popular_destinations(db)


@router.get("/agency-revenue", response_model=AgencyRevenueRow)
async def agency_revenue(
    date_from: date = Query(...), date_to: date = Query(...), db: AsyncSession = Depends(get_db)
):
    return await reports_service.agency_revenue(db, date_from, date_to)
