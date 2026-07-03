from decimal import Decimal

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/travel_agency_db"
    SECRET_KEY: str = "change-me-in-production"
    CORS_ORIGINS: list[str] = ["*"]

    #: Агентская комиссия по умолчанию — применяется к заявкам, которые клиент
    #: оформляет сам с витрины (сотрудник в админке может задать свою).
    DEFAULT_COMMISSION_PERCENT: Decimal = Decimal("10")

    #: Реквизиты для перевода. В MVP платёжного шлюза нет: клиент переводит
    #: сам и жмёт «Я оплатил», сотрудник подтверждает поступление вручную.
    PAYMENT_RECIPIENT: str = 'ООО «Турагентство Мечта»'
    PAYMENT_CARD_NUMBER: str = "0000 0000 0000 0000"
    PAYMENT_BANK_NAME: str = "Укажите банк в .env (PAYMENT_BANK_NAME)"
    PAYMENT_COMMENT: str = "В комментарии к переводу укажите номер бронирования."

    class Config:
        env_file = ".env"


settings = Settings()
