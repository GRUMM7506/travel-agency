from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, model_validator


class TourBase(BaseModel):
    tour_name: str
    country: str
    city: str
    start_date: date
    end_date: date
    base_price: Decimal
    hotel_id: int
    carrier_id: int
    notes: str | None = None
    image_url: str | None = None

    @model_validator(mode="after")
    def check_dates(self):
        if self.end_date <= self.start_date:
            raise ValueError("end_date должен быть позже start_date")
        return self


class TourCreate(TourBase):
    pass


class TourUpdate(TourBase):
    pass


class TourRead(TourBase):
    model_config = ConfigDict(from_attributes=True)
    tour_id: int
    duration_days: int | None = None


class TourReadWithRelations(TourRead):
    """Схема для витрины и списков — с данными отеля и перевозчика.

    Поля заполняются свойствами модели Tour (hotel_name, carrier_name, ...);
    остаются None, если связь не была подгружена через selectinload.
    """

    hotel_name: str | None = None
    hotel_stars: int | None = None
    hotel_image_url: str | None = None
    carrier_name: str | None = None
    transport_type: str | None = None
