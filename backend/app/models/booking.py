from datetime import date
from decimal import Decimal

from sqlalchemy import String, Text, Date, Numeric, Integer, ForeignKey, CheckConstraint
from sqlalchemy import inspect as sa_inspect
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Booking(Base):
    __tablename__ = "bookings"
    __table_args__ = (CheckConstraint("people_count > 0", name="chk_people_count"),)

    booking_id: Mapped[int] = mapped_column(primary_key=True)
    client_id: Mapped[int] = mapped_column(ForeignKey("clients.client_id"), nullable=False)
    tour_id: Mapped[int] = mapped_column(ForeignKey("tours.tour_id"), nullable=False)
    booking_date: Mapped[date] = mapped_column(Date, nullable=False)
    people_count: Mapped[int] = mapped_column(Integer, nullable=False)
    discount_percent: Mapped[Decimal] = mapped_column(Numeric(4, 2), default=0)
    commission_percent: Mapped[Decimal] = mapped_column(Numeric(4, 2), default=10)
    total_cost: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="оформлен")
    notes: Mapped[str | None] = mapped_column(Text)

    client: Mapped["Client"] = relationship(back_populates="bookings")
    tour: Mapped["Tour"] = relationship(back_populates="bookings")
    payments: Mapped[list["Payment"]] = relationship(back_populates="booking")

    # ------------------------------------------------------------------
    # Денормализованные поля для списков (BookingRead читает их напрямую).
    # Свойства безопасны при незагруженной связи: в async-сессии обращение
    # к lazy-связи вне greenlet-контекста упало бы с MissingGreenlet, поэтому
    # сначала спрашиваем у SQLAlchemy, загружена ли связь вообще.
    # ------------------------------------------------------------------

    def _loaded(self, name: str) -> bool:
        return name not in sa_inspect(self).unloaded

    @property
    def client_name(self) -> str | None:
        return self.client.full_name if self._loaded("client") else None

    @property
    def tour_name(self) -> str | None:
        return self.tour.tour_name if self._loaded("tour") else None

    @property
    def tour_country(self) -> str | None:
        return self.tour.country if self._loaded("tour") else None

    @property
    def tour_city(self) -> str | None:
        return self.tour.city if self._loaded("tour") else None

    @property
    def tour_start_date(self) -> date | None:
        return self.tour.start_date if self._loaded("tour") else None

    @property
    def tour_end_date(self) -> date | None:
        return self.tour.end_date if self._loaded("tour") else None
