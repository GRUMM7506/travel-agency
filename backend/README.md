# Travel Agency — Backend (FastAPI + PostgreSQL)

## Стек
- Python 3.11+
- FastAPI
- SQLAlchemy 2.x (async, psycopg3)
- Alembic (миграции)
- PostgreSQL 14+
- JWT-авторизация (PyJWT + bcrypt)

## Запуск

```bash
# 1. Создать виртуальное окружение
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Установить зависимости
pip install -r requirements.txt

# 3. Настроить окружение
cp .env.example .env
# отредактировать DATABASE_URL и ОБЯЗАТЕЛЬНО заменить SECRET_KEY

# 4. Создать БД в PostgreSQL
createdb travel_agency_db

# 5. Применить миграции
alembic upgrade head

# 6. Заполнить тестовыми данными
psql -d travel_agency_db -f seed_data.sql

# 7. Создать первого администратора (без него в CRM не войти)
ADMIN_EMAIL=admin@agency.local ADMIN_PASSWORD=admin123 \
  ADMIN_FULL_NAME="Админ Админов" python -m app.scripts.create_admin

# 8. Запустить сервер
uvicorn app.main:app --reload --port 8000
```

После запуска Swagger UI доступен на `http://localhost:8000/docs`.

## Авторизация

В системе **два независимых вида токенов**. Они не взаимозаменяемы: в payload JWT
лежит `"type": "staff"` или `"type": "client"`, и каждая зависимость проверяет своё
значение. Токен клиента в `/hotels` даст 401, токен сотрудника в `/auth/client/me` — тоже.

| | Сотрудник | Клиент |
|---|---|---|
| Регистрация | только админом через `POST /staff` | сам: `POST /auth/client/register` |
| Вход | `POST /auth/login` | `POST /auth/client/login` |
| Профиль | `GET /auth/me` | `GET /auth/client/me` |
| Доступ | вся CRM | только свои бронирования |

Роли сотрудников: `admin` (всё + управление сотрудниками) и `manager` (вся CRM,
кроме раздела `/staff`).

**Публичные эндпоинты без токена:** `GET /tours`, `GET /tours/search`,
`GET /tours/{id}` — их читает витрина туров, доступная незалогиненному посетителю.

## Жизненный цикл бронирования

`status` — не свободная строка, а `Literal` в `app/schemas/booking.py`.
Невалидное значение отбивается 422 ещё на уровне Pydantic.

```
заявка → ожидает оплаты → оплачен → завершён
                       ↘ отменён
```

- **ожидает оплаты** — ставится автоматически, когда клиент бронирует через `POST /bookings/self`
- **оплачен** — остаток закрыт: клиент оплатил картой (`POST /bookings/{id}/pay`)
  либо сотрудник внёс `Payment` вручную
- **на проверке** — остался для броней, оплаченных переводом до появления шлюза

Клиент через `PATCH /bookings/{id}/status` может выставить **только** «на проверке»
или «отменён», и только своей броне. Всё остальное — прерогатива сотрудника.

### Оплата картой

`POST /bookings/{id}/pay` — **демонстрационный** шлюз, не эквайринг. Форма карты
живёт целиком на клиенте (`lib/widgets/checkout_sheet.dart`): номер, срок и CVC
никуда не отправляются и нигде не хранятся, «проведение платежа» имитируется
задержкой. На сервер уходят только последние 4 цифры — для строки «карта ****1111»
в истории. Всё остальное настоящее: создаётся `Payment` на весь остаток,
бронь переводится в «оплачен», отчёты и баланс считаются по этим данным.

Эндпоинт доступен владельцу брони и сотруднику; повторная оплата и оплата
отменённой брони отбиваются 409. Платежи произвольной суммой (`POST /payments`,
частичные и наличные) по-прежнему заводит только сотрудник.

## Структура

```
app/
├── models/     # SQLAlchemy ORM-модели (таблицы)
├── schemas/    # Pydantic-схемы (валидация запросов/ответов)
├── crud/       # низкоуровневые операции с БД
├── services/   # бизнес-логика (расчёт стоимости, остаток, отчёты)
├── routers/    # эндпоинты FastAPI
├── api/        # зависимости авторизации (get_current_staff / get_current_client)
├── core/       # конфигурация, подключение к БД, хеширование и JWT
├── scripts/    # разовые скрипты (создание админа)
└── main.py     # точка входа
```

## Alembic — создание новой миграции

```bash
alembic revision --autogenerate -m "описание изменений"
alembic upgrade head
```

Текущие миграции: `0001` схема → `0002` картинки → `0003` таблица staff →
`0004` аккаунты клиентов (`password_hash`, `is_registered` на `clients`).

## Нюансы

### passlib не используется

Последний релиз passlib — 1.7.4 (2020) — падает с bcrypt ≥ 4.1
(`ValueError: password cannot be longer than 72 bytes`). `app/core/security.py`
работает с `bcrypt` напрямую и сам обрезает пароль до 72 байт.

### Пакет для JWT — именно PyJWT

В PyPI есть пакет-однофамилец `jwt` (другого автора) с несовместимым API.
Ставьте `pyjwt`, иначе `from jwt.exceptions import PyJWTError` упадёт с ImportError.

### Windows

`psycopg[binary]` в async-режиме не работает с дефолтным `ProactorEventLoop`
(ошибка `psycopg.InterfaceError: Psycopg cannot use the 'ProactorEventLoop'...`).
В `app/core/database.py` и `alembic/env.py` уже стоит переключение на
`WindowsSelectorEventLoopPolicy`, так что это должно работать «из коробки».
Если ошибка всё же появляется (например, при кастомном запуске), добавьте
в самое начало своего entry-point скрипта:

```python
import asyncio, sys
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
```

Также убедитесь, что `greenlet` установлен (`pip install greenlet`) — SQLAlchemy async
требует его явно, но он не всегда подтягивается как транзитивная зависимость.
