# Автоматизация туристического агентства

Курсовой проект: PostgreSQL + Python (FastAPI) + Flutter.

## Структура репозитория

```
travel-agency/
├── backend/     # FastAPI + SQLAlchemy + Alembic + PostgreSQL
│   └── README.md
└── frontend/    # Flutter (Provider + GoRouter + Dio)
    └── README.md
```

## Быстрый старт

### 1. Backend

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # указать свои данные PostgreSQL
createdb travel_agency_db
alembic upgrade head
psql -d travel_agency_db -f seed_data.sql
uvicorn app.main:app --reload --port 8000
```

Swagger UI: http://localhost:8000/docs

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Модель данных

6 таблиц: `hotels`, `carriers`, `clients`, `tours`, `bookings`, `payments`.
Подробная ER-схема и SQL-запросы — в `backend/README.md` и в плане проекта
(`travel_agency_plan.md`, отправленном ранее).

## Что уже готово в скелете

- ✅ Полная структура backend: модели, схемы, CRUD, роутеры, сервисы (расчёт стоимости, отчёты)
- ✅ Alembic-миграция `0001_initial_schema` с констрейнтами и индексами
- ✅ `seed_data.sql` — тестовые данные (70+ записей суммарно по всем таблицам)
- ✅ Полная структура frontend: модели, Dio-сервисы, Provider'ы, экраны, тёмная glassmorphism-тема
- ✅ Расчёт стоимости бронирования выполняется на бэкенде (единый источник истины)

## Что нужно доделать перед сдачей

- [ ] Дополнить пояснительную записку (анализ предметной области, ER-диаграмма — см. план)
- [ ] Прогнать реальные сценарии end-to-end и снять скриншоты для отчёта
- [ ] При необходимости — добавить JWT-авторизацию по аналогии с ERP-проектом
- [ ] Добавить unit-тесты (pytest для backend, flutter_test для frontend) — не входят в стандартные требования, но плюс к оценке
