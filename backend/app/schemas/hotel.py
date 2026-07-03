from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class HotelBase(BaseModel):
    hotel_name: str
    country: str
    city: str
    address: str | None = None
    category: str | None = None
    star_rating: int | None = None
    phone: str | None = None
    email: str | None = None
    night_price: Decimal
    notes: str | None = None
    image_url: str | None = None


class HotelCreate(HotelBase):
    pass


class HotelUpdate(HotelBase):
    pass


class HotelRead(HotelBase):
    model_config = ConfigDict(from_attributes=True)
    hotel_id: int
