from decimal import Decimal

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/travel_agency_db"
    SECRET_KEY: str = "change-me-in-production"
    CORS_ORIGINS: list[str] = ["*"]

    #: Агентская комиссия по умолчанию — применяется к заявкам, которые клиент
    #: оформляет сам с витрины (сотрудник в админке может задать свою).
    DEFAULT_COMMISSION_PERCENT: Decimal = Decimal("10")

    class Config:
        env_file = ".env"
        # Оплата по реквизитам заменена демо-шлюзом, но PAYMENT_* могли
        # остаться в чьём-нибудь .env — лишние переменные не должны ронять старт.
        extra = "ignore"


settings = Settings()
