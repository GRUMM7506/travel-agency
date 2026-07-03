from datetime import date
from decimal import Decimal

from sqlalchemy import String, Text, Date, Numeric, ForeignKey, Computed, Integer
from sqlalchemy import inspect as sa_inspect
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Tour(Base):
    __tablename__ = "tours"

    tour_id: Mapped[int] = mapped_column(primary_key=True)
    tour_name: Mapped[str] = mapped_column(String(100), nullable=False)
    country: Mapped[str] = mapped_column(String(50), nullable=False)
    city: Mapped[str] = mapped_column(String(50), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    base_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    hotel_id: Mapped[int] = mapped_column(ForeignKey("hotels.hotel_id"), nullable=False)
    carrier_id: Mapped[int] = mapped_column(ForeignKey("carriers.carrier_id"), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(500))
    # generated column, вычисляется на стороне PostgreSQL
    duration_days: Mapped[int | None] = mapped_column(
        Integer, Computed("end_date - start_date", persisted=True)
    )

    hotel: Mapped["Hotel"] = relationship(back_populates="tours")
    carrier: Mapped["Carrier"] = relationship(back_populates="tours")
    bookings: Mapped[list["Booking"]] = relationship(back_populates="tour")

    # Витрине нужны названия отеля и перевозчика, а не только их id.
    # Свойства безопасны при незагруженной связи — см. комментарий в booking.py.

    def _loaded(self, name: str) -> bool:
        return name not in sa_inspect(self).unloaded

    @property
    def hotel_name(self) -> str | None:
        return self.hotel.hotel_name if self._loaded("hotel") else None

    @property
    def hotel_stars(self) -> int | None:
        return self.hotel.star_rating if self._loaded("hotel") else None

    @property
    def hotel_image_url(self) -> str | None:
        return self.hotel.image_url if self._loaded("hotel") else None

    @property
    def carrier_name(self) -> str | None:
        return self.carrier.company_name if self._loaded("carrier") else None

    @property
    def transport_type(self) -> str | None:
        return self.carrier.transport_type if self._loaded("carrier") else None
