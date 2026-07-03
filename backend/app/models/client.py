from datetime import date

from sqlalchemy import Boolean, String, Text, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Client(Base):
    __tablename__ = "clients"

    client_id: Mapped[int] = mapped_column(primary_key=True)
    last_name: Mapped[str] = mapped_column(String(50), nullable=False)
    first_name: Mapped[str] = mapped_column(String(50), nullable=False)
    middle_name: Mapped[str | None] = mapped_column(String(50))
    birth_date: Mapped[date | None] = mapped_column(Date)
    phone: Mapped[str | None] = mapped_column(String(20))
    email: Mapped[str | None] = mapped_column(String(100))
    address: Mapped[str | None] = mapped_column(String(150))
    passport: Mapped[str | None] = mapped_column(String(30))
    foreign_passport: Mapped[str | None] = mapped_column(String(30))
    notes: Mapped[str | None] = mapped_column(Text)
    # Логин клиента живёт прямо на карточке клиента — это тот же человек,
    # заведённый либо сотрудником вручную, либо самостоятельной регистрацией.
    password_hash: Mapped[str | None] = mapped_column(String(255))
    is_registered: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    bookings: Mapped[list["Booking"]] = relationship(back_populates="client")

    @property
    def full_name(self) -> str:
        return f"{self.last_name} {self.first_name}".strip()
