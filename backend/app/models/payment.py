from datetime import date
from decimal import Decimal

from sqlalchemy import String, Text, Date, Numeric, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Payment(Base):
    __tablename__ = "payments"

    payment_id: Mapped[int] = mapped_column(primary_key=True)
    booking_id: Mapped[int] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    # server_default обязателен не только в миграции, но и здесь: без него
    # SQLAlchemy подставляет в INSERT явный NULL, когда дата не передана
    # (а её не передают ни экран платежей, ни демо-шлюз), и падает на NOT NULL.
    payment_date: Mapped[date] = mapped_column(
        Date, nullable=False, server_default=func.current_date()
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    payment_method: Mapped[str | None] = mapped_column(String(30))
    notes: Mapped[str | None] = mapped_column(Text)

    booking: Mapped["Booking"] = relationship(back_populates="payments")
