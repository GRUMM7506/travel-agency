# Автоматизация туристического агентства

Курсовой проект: PostgreSQL + Python (FastAPI) + Flutter.

## Структура репозитория

```
travel-agency/
├── backend/     # FastAPI + SQLAlchemy + Alembic + PostgreSQL
│   └── README.md
├── lib/         # Flutter-приложение (Provider + GoRouter + Dio) — в корне репозитория
├── scripts/     # батники для локального запуска и бэкапа БД (см. ниже)
├── android/ ios/ web/ windows/ linux/ macos/   # платформенные обёртки Flutter
└── .github/workflows/   # CI: автодеплой веба на GitHub Pages, ручная сборка APK
```

## Быстрый старт (Windows)

Проще всего — готовые батники в `scripts/`:

```
scripts\run-local.bat        REM backend + Flutter web (Chrome) одной командой
scripts\start-backend.bat    REM только backend: venv, миграции, uvicorn на :8000
scripts\start-frontend.bat   REM только Flutter web, целится в http://127.0.0.1:8000
scripts\backup-db.bat        REM pg_dump локальной БД в scripts/backups/
scripts\restore-db.bat       REM восстановление из scripts/backups/ (или перетащить файл)
```

Перед первым запуском скопируйте `backend/.env.example` в `backend/.env` и
укажите свой `DATABASE_URL` — батники берут параметры подключения оттуда.
Админа для входа в CRM создать отдельно (см. `backend/README.md`, раздел «Запуск», шаг 7).

## Быстрый старт (вручную, любая ОС)

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
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Деплой

- **Backend на сервер** — `docker-compose.yml` в корне репозитория поднимает
  `db` (Postgres) + `backend` + `cloudflared` (бесплатный HTTPS-туннель без
  своего домена): `docker compose -p travel-agency up -d --build`.
- **Веб-версия** — `.github/workflows/deploy-web.yml` автоматически собирает
  Flutter web и публикует на GitHub Pages при каждом push в `main`. Адрес
  backend берётся из repo-переменной `API_BASE_URL` (Settings → Secrets and
  variables → Actions → Variables).
- **Android APK** — `.github/workflows/build-apk.yml`, запуск вручную (Actions →
  Build Android APK (manual) → Run workflow), готовый `.apk` — в Artifacts
  этого запуска. Использует ту же переменную `API_BASE_URL`.

## Модель данных

6 таблиц: `hotels`, `carriers`, `clients`, `tours`, `bookings`, `payments`.
Подробная ER-схема и SQL-запросы — в `backend/README.md` и в плане проекта
(`travel_agency_plan.md`, отправленном ранее).

## Что уже готово

- ✅ Полная структура backend: модели, схемы, CRUD, роутеры, сервисы (расчёт стоимости, отчёты)
- ✅ Alembic-миграции `0001`–`0004`: схема, картинки, таблица `staff`, аккаунты клиентов
- ✅ `seed_data.sql` — тестовые данные (70+ записей суммарно по всем таблицам)
- ✅ JWT-авторизация: два независимых вида токенов (сотрудник / клиент), см. `backend/README.md`
- ✅ Демонстрационная оплата картой (`POST /bookings/{id}/pay`)
- ✅ Полная структура frontend: модели, Dio-сервисы, Provider'ы, экраны, тёмная glassmorphism-тема
- ✅ Расчёт стоимости бронирования выполняется на бэкенде (единый источник истины)
- ✅ Docker-деплой backend (`docker-compose.yml`) + автодеплой веба на GitHub Pages + ручная сборка APK

## Что нужно доделать перед сдачей

- [ ] Дополнить пояснительную записку (анализ предметной области, ER-диаграмма — см. план)
- [ ] Прогнать реальные сценарии end-to-end и снять скриншоты для отчёта
- [ ] Добавить unit-тесты (pytest для backend, flutter_test для frontend) — не входят в стандартные требования, но плюс к оценке
- [ ] Заменить временный `trycloudflare.com`-адрес backend на постоянный домен перед финальной сдачей (см. раздел «Деплой»)
