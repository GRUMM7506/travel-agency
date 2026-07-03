# План проекта «Автоматизация туристического агентства»
### Стек: PostgreSQL + Python (FastAPI) + Flutter

---

## 1. Архитектура проекта

```
travel-agency/
├── backend/
│   ├── app/
│   │   ├── models/          # SQLAlchemy модели
│   │   ├── schemas/         # Pydantic-схемы
│   │   ├── routers/         # эндпоинты FastAPI
│   │   ├── services/        # бизнес-логика (расчёт стоимости, отчёты)
│   │   ├── crud/            # CRUD-операции
│   │   ├── core/             # конфиг, подключение к БД
│   │   └── main.py
│   ├── alembic/               # миграции 0001 → 000N
│   └── requirements.txt
└── frontend/
    └── lib/
        ├── models/
        ├── services/          # Dio API-клиент
        ├── providers/         # Provider state management
        ├── screens/
        │   ├── tours/
        │   ├── clients/
        │   ├── bookings/
        │   ├── payments/
        │   └── reports/
        └── widgets/
```

---

## 2. Инфологическая модель

| Сущность | Назначение | Связи |
|---|---|---|
| **Клиенты** | Кто покупает туры | 1 → М с Бронированием |
| **Туры** | Каталог турпродуктов | 1 → М с Бронированием; М → 1 с Гостиницами; М → 1 с Перевозчиками |
| **Гостиницы** | Справочник размещения | 1 → М с Турами |
| **Перевозчики** | Справочник транспорта | 1 → М с Турами |
| **Бронирования** | Факт продажи (связка Клиент–Тур) | М → 1 с Клиентами и Турами; 1 → М с Оплатой |
| **Оплата** | Платежи по бронированию | М → 1 с Бронированием |

### Схема связей (ER, текстово)

```
Гостиницы (1) ────< Туры (М) >──── (1) Перевозчики
                         │
                         │ (1)
                         ▼ (М)
Клиенты (1) ────< Бронирования >
                         │ (1)
                         ▼ (М)
                      Оплата
```

Диаграмму рекомендуется построить в draw.io или pgAdmin ER-tool и вставить в пояснительную записку.

---

## 3. Модель данных (DDL, PostgreSQL)

```sql
CREATE TABLE hotels (
    hotel_id       SERIAL PRIMARY KEY,
    hotel_name     VARCHAR(100) NOT NULL,
    country        VARCHAR(50) NOT NULL,
    city           VARCHAR(50) NOT NULL,
    address        VARCHAR(150),
    category       VARCHAR(20),
    star_rating    SMALLINT CHECK (star_rating BETWEEN 1 AND 5),
    phone          VARCHAR(20),
    email          VARCHAR(100),
    night_price    NUMERIC(10,2) NOT NULL,
    notes          TEXT
);

CREATE TABLE carriers (
    carrier_id     SERIAL PRIMARY KEY,
    company_name   VARCHAR(100) NOT NULL,
    transport_type VARCHAR(30) NOT NULL,
    contact_person VARCHAR(100),
    phone          VARCHAR(20),
    email          VARCHAR(100),
    address        VARCHAR(150),
    trip_cost      NUMERIC(10,2) NOT NULL,
    schedule       VARCHAR(100),
    notes          TEXT
);

CREATE TABLE clients (
    client_id        SERIAL PRIMARY KEY,
    last_name        VARCHAR(50) NOT NULL,
    first_name       VARCHAR(50) NOT NULL,
    middle_name      VARCHAR(50),
    birth_date       DATE,
    phone            VARCHAR(20),
    email            VARCHAR(100),
    address          VARCHAR(150),
    passport         VARCHAR(30),
    foreign_passport VARCHAR(30),
    notes            TEXT
);

CREATE TABLE tours (
    tour_id        SERIAL PRIMARY KEY,
    tour_name      VARCHAR(100) NOT NULL,
    country        VARCHAR(50) NOT NULL,
    city           VARCHAR(50) NOT NULL,
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    base_price     NUMERIC(10,2) NOT NULL,
    hotel_id       INT NOT NULL REFERENCES hotels(hotel_id),
    carrier_id     INT NOT NULL REFERENCES carriers(carrier_id),
    notes          TEXT,
    CONSTRAINT chk_dates CHECK (end_date > start_date)
);

-- вычисляемая длительность (generated column, PostgreSQL 12+)
ALTER TABLE tours ADD COLUMN duration_days INT
    GENERATED ALWAYS AS (end_date - start_date) STORED;

CREATE TABLE bookings (
    booking_id         SERIAL PRIMARY KEY,
    client_id          INT NOT NULL REFERENCES clients(client_id),
    tour_id            INT NOT NULL REFERENCES tours(tour_id),
    booking_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    people_count       INT NOT NULL CHECK (people_count > 0),
    discount_percent   NUMERIC(4,2) DEFAULT 0,
    commission_percent NUMERIC(4,2) DEFAULT 10,
    total_cost         NUMERIC(10,2) NOT NULL,
    status              VARCHAR(20) DEFAULT 'оформлен',
    notes               TEXT
);

CREATE TABLE payments (
    payment_id     SERIAL PRIMARY KEY,
    booking_id     INT NOT NULL REFERENCES bookings(booking_id),
    payment_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    amount         NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(30),
    notes          TEXT
);

-- индексы для поиска/фильтрации
CREATE INDEX idx_tours_country ON tours(country);
CREATE INDEX idx_tours_dates ON tours(start_date, end_date);
CREATE INDEX idx_clients_lastname ON clients(last_name);
CREATE INDEX idx_bookings_date ON bookings(booking_date);
```

Миграции через Alembic: `0001_initial_schema`, далее по необходимости `0002_add_indexes` и т.д.

---

## 4. Backend: ключевые эндпоинты (FastAPI)

```
GET/POST/PUT/DELETE  /hotels
GET/POST/PUT/DELETE  /carriers
GET/POST/PUT/DELETE  /clients
GET/POST/PUT/DELETE  /tours          + фильтрация (country, price_min/max, date_from/to)
GET/POST/PUT/DELETE  /bookings       + расчёт total_cost на бэкенде при создании
GET/POST/PUT/DELETE  /payments
GET  /reports/sales?date_from=&date_to=
GET  /reports/popular-destinations
GET  /reports/agency-revenue?period=month
GET  /search/tours?q=
GET  /search/clients?q=
```

Расчёт стоимости — в `services/booking_service.py`, не в модели:

```python
def calc_total_cost(base_price, people_count, discount_percent):
    return round(base_price * people_count * (1 - discount_percent / 100), 2)
```

---

## 5. SQL-запросы (примеры для отчёта по проекту)

```sql
-- Выборка
SELECT tour_name, country, base_price FROM tours WHERE country = 'Турция';

-- Сортировка
SELECT * FROM tours ORDER BY base_price DESC;

-- Группировка + агрегатные функции
SELECT country, COUNT(*) AS tour_count, AVG(base_price) AS avg_price
FROM tours GROUP BY country;

-- Многотабличный запрос (JOIN)
SELECT c.last_name, c.first_name, t.tour_name, b.total_cost, b.booking_date
FROM bookings b
JOIN clients c ON b.client_id = c.client_id
JOIN tours t ON b.tour_id = t.tour_id
ORDER BY b.booking_date DESC;

-- Доход агентства за период
SELECT SUM(total_cost * commission_percent / 100) AS total_commission
FROM bookings
WHERE booking_date BETWEEN '2026-01-01' AND '2026-06-30';
```

---

## 6. Вычисления

| Вычисление | Формула |
|---|---|
| Стоимость тура на человека | `tours.base_price` |
| Стоимость бронирования | `base_price * people_count * (1 - discount_percent/100)` |
| Комиссия агентства | `total_cost * commission_percent / 100` |
| Прибыль по туру | `Комиссия - расходы на организацию` |
| Скидка для групп | реализуется в форме/сервисе бронирования |

---

## 7. Frontend: экраны Flutter

- `TourListScreen` — список/карточки туров, фильтр (страна, диапазон дат, диапазон цен) + поиск
- `TourFormScreen` — добавление/редактирование, dropdown Hotel/Carrier
- `ClientListScreen` / `ClientFormScreen` — CRUD клиентов, поиск по ФИО/телефону
- `BookingFormScreen` — выбор клиента и тура, ввод количества человек и скидки, авторасчёт итоговой суммы через API
- `PaymentScreen` — привязка оплаты к бронированию
- `ReportsScreen` — вкладки: продажи, популярные направления, доход агентства (таблицы/графики через `fl_chart`)
- `HotelListScreen` / `CarrierListScreen` — CRUD-справочники

---

## 8. Отчёты

1. **Продажи туров** — список бронирований за период с суммами
2. **Популярные направления** — `GROUP BY country/city ORDER BY COUNT(*) DESC`
3. **Доход агентства** — сумма комиссий за месяц/квартал
4. **Загрузка по гостиницам** — количество туров/броней на гостиницу
5. **Топ клиентов** — по сумме покупок

---

## 9. План по дням (14 дней, ~2-3 часа в день)

### Этап 1 — Проектирование и БД (дни 1-2)

**День 1**
- Анализ предметной области, раздел в пояснительной записке
- Финализация инфологической модели, ER-диаграмма (draw.io)
- Установка PostgreSQL, создание БД `travel_agency_db`

**День 2**
- DDL-скрипт (таблицы, PK/FK, constraints, индексы)
- Настройка Alembic, первая ревизия `0001_initial_schema`
- Наполнение тестовыми данными (50+ записей суммарно)

### Этап 2 — Backend: основа (дни 3-5)

**День 3**
- Инициализация FastAPI-проекта, структура папок
- Подключение к PostgreSQL (SQLAlchemy 2.x + psycopg3, async engine)
- SQLAlchemy-модели для всех 6 таблиц

**День 4**
- Pydantic-схемы (Create/Update/Read) для каждой сущности
- CRUD-слой (`crud/hotels.py`, `crud/clients.py` и т.д.)
- Роутеры для справочников: Hotels, Carriers, Clients

**День 5**
- Роутер Tours с фильтрацией и поиском
- Роутер Bookings с бизнес-логикой расчёта `total_cost`
- Роутер Payments
- Тестирование через Swagger UI (`/docs`)

### Этап 3 — Backend: отчёты и доработка (день 6)

**День 6**
- SQL-запросы для отчётов, `services/reports_service.py`
- Эндпоинты `/reports/*`
- Валидация (`end_date > start_date`, `people_count > 0`)
- Настройка CORS для Flutter

### Этап 4 — Flutter: основа (дни 7-8)

**День 7**
- Инициализация Flutter-проекта, структура папок
- Dio-клиент (`ApiService`), базовый URL, обработка ошибок
- Dart-модели (`fromJson`/`toJson`) для всех сущностей
- Настройка GoRouter и Provider

**День 8**
- Экраны справочников: Hotels, Carriers (список + форма CRUD)
- Переиспользуемые виджеты (таблица данных, форма ввода, диалог подтверждения удаления)

### Этап 5 — Flutter: основной функционал (дни 9-11)

**День 9**
- Экран Clients: список, форма CRUD, поиск по ФИО/телефону

**День 10**
- Экран Tours: карточки, форма добавления (dropdown Hotel/Carrier), фильтрация

**День 11**
- Экран Bookings: выбор клиента и тура, ввод людей/скидки, вызов API расчёта, статус брони

### Этап 6 — Оплата и отчёты во Flutter (дни 12-13)

**День 12**
- Экран Payments: список платежей, форма добавления, обновление статуса бронирования

**День 13**
- Экран Reports: вкладки (продажи, направления, доход), таблицы/графики (`fl_chart`)
- Полировка UI

### Этап 7 — Тестирование и документация (день 14)

**День 14**
- Сквозное тестирование (тур → бронирование → оплата → отчёт)
- Проверка ограничений целостности (FK, каскады)
- Пояснительная записка: скриншоты, ER-диаграмма, SQL-запросы, вычисления
- README (структура проекта, инструкция запуска backend + frontend)

---

## 10. Сжатый вариант (7-8 дней)

Если времени мало — объединить этапы:

| Дни | Содержание |
|---|---|
| 1 | БД + миграции + тестовые данные |
| 2-3 | Весь backend CRUD (модели, схемы, роутеры) |
| 4 | Отчёты и доработка backend |
| 5-7 | Flutter: все экраны без разделения по дням на каждый |
| 8 | Тестирование, документация |