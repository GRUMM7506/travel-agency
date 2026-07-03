from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class CarrierBase(BaseModel):
    company_name: str
    transport_type: str
    contact_person: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    trip_cost: Decimal
    schedule: str | None = None
    notes: str | None = None
    image_url: str | None = None


class CarrierCreate(CarrierBase):
    pass


class CarrierUpdate(CarrierBase):
    pass


class CarrierRead(CarrierBase):
    model_config = ConfigDict(from_attributes=True)
    carrier_id: int
