# Travel Agency → MVP: план в 2 трека

## Текущее состояние (для контекста)

**Backend** (FastAPI + SQLAlchemy async + PostgreSQL, структура `routers → crud/services → models/schemas`):
- Сущности: Hotel, Carrier, Client, Tour, Booking, Payment — везде полный CRUD.
- Авторизации **нет вообще**. Любой запрос к API проходит без проверки.
- `Booking.status` — свободная строка (`"оформлен"` по умолчанию), без enum/constraint.
- `payment_service.py` пустой — остаток к оплате (total_cost − сумма платежей) нигде не считается.

**Flutter** (Provider + go_router + Dio, структура `models → services → providers → screens`):
- Админ-экраны для всех 6 сущностей — списки, формы, готово.
- `client_mode_screen.dart` — публичная витрина туров (поиск/фильтры/сортировка/избранное), избранное живёт только в памяти.
- Забронировать тур из витрины нельзя — бронирование создаёт только сотрудник из админки.
- Токенов, интерсепторов, guard'ов в роутере — нет.

## Как читать этот план

Два трека идут **последовательно**: сначала весь трек A (CRM с логином), потом трек B (клиентский кабинет поверх). Внутри трека этапы тоже последовательны — не давай локальной модели два этапа за один раз, и не начинай трек B, пока не закрыт трек A.

Каждый этап = один промпт. Промпт уже содержит:
- **Контекст** — что уже есть, на что ориентироваться по стилю кода.
- **Задача** — что сделать, с точными именами файлов.
- **Не трогать** — явный стоп-лист, чтобы модель не полезла чинить/переписывать соседний код "по пути" (главная причина конфликтов между этапами).
- **Готово, когда** — критерий завершения, чтобы ты мог проверить перед тем, как двигаться дальше.

Перед запуском каждого промпта вставляй в чат модели только те файлы, которые перечислены в "Контекст" — не весь проект. Маленькие локальные модели теряются в большом контексте и начинают "исправлять" то, что их не просили.

---

## ТРЕК A — CRM с логином для сотрудников

### A1. Backend: модель сотрудника + JWT-авторизация

```
Контекст: FastAPI-проект travel-agency. Async SQLAlchemy 2.0 (Mapped/mapped_column),
Base из app/core/database.py, сессия через Depends(get_db). Настройки — pydantic-settings
в app/core/config.py (класс Settings, объект settings, поля DATABASE_URL, SECRET_KEY,
CORS_ORIGINS). Роутеры лежат в app/routers/*.py и подключаются в app/main.py через
app.include_router(...). Файлы моделей — app/models/*.py, схемы — app/schemas/*.py,
CRUD — app/crud/*.py.

Задача:
1. Добавить в requirements.txt: passlib[bcrypt] и python-jose[cryptography] (или pyjwt —
   выбери один и будь последователен).
2. Создать app/models/staff.py — модель Staff: staff_id (PK), full_name (str),
   email (str, unique), password_hash (str), role (str, default "manager", допустимые
   значения "admin"/"manager" — без строгого enum в БД, проверка на уровне Pydantic),
   is_active (bool, default True).
3. Создать app/schemas/auth.py: StaffLogin (email, password), Token (access_token,
   token_type="bearer"), StaffRead (staff_id, full_name, email, role) — без password_hash.
4. Создать app/core/security.py: хеширование/проверка пароля через passlib,
   create_access_token(data: dict, expires_minutes: int = 60*8) -> str на основе
   settings.SECRET_KEY, алгоритм HS256.
5. Создать app/api/deps.py: get_current_staff(token из заголовка Authorization: Bearer,
   через OAuth2PasswordBearer(tokenUrl="/auth/login")) — декодирует JWT, достаёт staff_id,
   грузит Staff из БД, кидает HTTPException 401 если токен невалиден или сотрудник не найден
   или is_active=False.
6. Создать app/routers/auth.py: POST /auth/login (принимает StaffLogin, проверяет пароль,
   возвращает Token), GET /auth/me (Depends(get_current_staff), возвращает StaffRead).
7. Подключить auth.router в app/main.py.
8. На ВСЕ существующие роутеры (hotels, carriers, clients, tours, bookings, payments,
   reports) добавить Depends(get_current_staff) как зависимость эндпоинтов — либо через
   dependencies=[Depends(get_current_staff)] в APIRouter(...), это предпочтительнее,
   чем дублировать в каждой функции.
9. Создать alembic-миграцию для таблицы staff и добавить одного стартового admin
   через отдельный скрипт app/scripts/create_admin.py (email/password берутся из
   переменных окружения ADMIN_EMAIL/ADMIN_PASSWORD, если их нет — печатает подсказку
   и не создаёт пользователя).

Не трогать: HotelBase/CarrierBase/... схемы, бизнес-логику booking_service.py,
существующие CRUD-функции — только добавь зависимость в роутер, саму сигнатуру
функций эндпоинтов не меняй если не обязательно.

Готово, когда: без валидного Bearer-токена любой запрос к /hotels, /tours, /bookings
и т.д. возвращает 401; POST /auth/login с верным email/паролем возвращает access_token;
GET /auth/me с этим токеном возвращает данные сотрудника.
```

### A2. Flutter: экран логина + защита маршрутов

```
Контекст: Flutter-приложение (Provider + ChangeNotifier + go_router + Dio).
Единый Dio-клиент — синглтон ApiService.instance.client (lib/services/api_service.dart),
baseUrl = kApiBaseUrl. Роутинг — lib/router.dart (GoRouter с path-based маршрутами,
без guard'ов сейчас). Провайдеры регистрируются в lib/main.dart через MultiProvider.
Экраны лежат в lib/screens/<entity>/..., паттерн сервиса — Dio-вызовы к REST,
модели через fromJson/toJson (см. lib/services/tour_service.dart и lib/models/tour.dart
как образец стиля).

Backend теперь требует JWT: POST /auth/login (email, password) -> {access_token,
token_type}, GET /auth/me -> данные сотрудника. Без заголовка
"Authorization: Bearer <token>" все /hotels, /tours, /bookings и т.д. отдают 401.

Задача:
1. lib/models/staff.dart — модель Staff (staffId, fullName, email, role) с fromJson.
2. lib/services/auth_service.dart — login(email, password) -> Token, me() -> Staff.
3. lib/providers/auth_provider.dart (ChangeNotifier) — хранит currentStaff, isAuthenticated,
   методы login(email, password), logout(), tryAutoLogin() (проверяет сохранённый токен
   при старте). Токен храни через пакет flutter_secure_storage (добавь в pubspec.yaml).
4. Добавить перехватчик в ApiService: interceptors.add(InterceptorsWrapper с onRequest,
   который читает токен из secure storage и добавляет заголовок Authorization). Если
   ответ 401 — очищай токен и (через callback/GetIt/статический стрим) сигналь
   AuthProvider о разлогине.
5. lib/screens/login_screen.dart — простая форма email+пароль, вызывает
   context.read<AuthProvider>().login(...), показывает ошибку через
   ApiService.instance.parseError.
6. lib/router.dart — добавить route '/login', и redirect-логику на уровне GoRouter
   (redirect: в GoRouter конструкторе), которая: если !isAuthenticated и путь начинается
   с '/admin' или это один из CRUD-путей (/tours, /clients, /bookings, /hotels, /carriers,
   /reports, /settings) — редиректить на '/login'; '/' (витрина туров) оставить доступной
   без логина.
7. main.dart — зарегистрировать AuthProvider в MultiProvider ПЕРЕД остальными провайдерами
   (они его пока не используют, порядок важен только для более простого будущего доступа),
   вызвать tryAutoLogin() при старте.
8. Добавить кнопку "Выйти" в settings_screen.dart, вызывающую logout().

Не трогать: существующие *_provider.dart для Hotel/Carrier/Client/Tour/Booking/Payment/
Report — их данные и так пойдут через тот же Dio-синглтон с уже прикреплённым токеном,
их логику менять не нужно. Не меняй client_mode_screen.dart — это следующий трек.

Готово, когда: без логина '/admin' и другие CRUD-экраны редиректят на '/login';
после успешного логина токен сохраняется и переживает перезапуск приложения (autologin);
после logout защищённые экраны снова недоступны.
```

### A3. Статусы бронирования + остаток к оплате

```
Контекст: см. Booking модель (app/models/booking.py) — поле status: str,
свободная строка, сейчас без ограничений. Payment (app/models/payment.py) —
отдельная таблица платежей по booking_id. app/services/payment_service.py
сейчас пустой файл.

Задача (backend):
1. В app/schemas/booking.py заменить status: str на Literal["заявка", "оформлен",
   "оплачен", "завершён", "отменён"] в BookingBase (используй typing.Literal),
   default оставь "оформлен".
2. Заполнить app/services/payment_service.py функцией
   async def get_balance(db, booking_id) -> dict с полями total_cost, paid_amount,
   remaining (total_cost - сумма всех Payment.amount по этому booking_id).
3. В app/routers/bookings.py добавить GET /bookings/{booking_id}/balance,
   возвращающий этот словарь (заведи Pydantic-схему BookingBalance в app/schemas/booking.py).
4. В app/schemas/booking.py добавить в BookingRead (не в Base!) вычисляемые поля
   не нужно — просто убедись что фронт может получить остаток отдельным запросом.

Задача (Flutter):
5. lib/services/booking_service.dart — добавить getBalance(int bookingId) -> Map
   (total_cost, paid_amount, remaining) через GET /bookings/{id}/balance.
6. lib/screens/payments/payment_screen.dart — отобразить остаток к оплате (запросить
   через getBalance при открытии экрана), обновлять после добавления платежа.

Не трогать: BookingCreate/BookingUpdate помимо замены типа status, calc_total_cost/
calc_commission в booking_service.py — они уже верные, не пересчитывай логику.

Готово, когда: попытка создать/обновить бронирование с status="что-то левое"
возвращает 422 от Pydantic; GET /bookings/{id}/balance отдаёт корректный остаток;
на экране оплаты сотрудник видит остаток и он уменьшается после добавления платежа.
```

Трек A закрыт → у тебя рабочий закрытый CRM с логином, ролями (пока не enforced, но поле есть) и видимым остатком долга. Дальше — клиентский кабинет.

---

## ТРЕК B — клиентский кабинет поверх CRM

### B1. Backend: аккаунты клиентов

```
Контекст: тот же стек. Модель Client (app/models/client.py) сейчас — просто
карточка клиента без логина/пароля, создаётся сотрудником. Нужно дать клиентам
возможность самим регистрироваться и логиниться, привязываясь к существующей
или новой записи Client. Auth для сотрудников уже сделан в app/core/security.py
(create_access_token, хеширование паролей) и app/api/deps.py (get_current_staff) —
переиспользуй эти же функции, не пиши хеширование пароля заново.

Задача:
1. Добавить в Client (app/models/client.py) поля: password_hash: str | None,
   is_registered: bool default False. НЕ создавай отдельную таблицу — проще держать
   логин прямо на Client, так как это тот же человек.
2. app/schemas/auth.py — добавить ClientRegister (first_name, last_name, email,
   phone, password), ClientLogin (email, password).
3. app/api/deps.py — добавить get_current_client (тот же принцип что
   get_current_staff, но грузит Client и проверяет is_registered=True), отдельный
   OAuth2PasswordBearer(tokenUrl="/auth/client/login") чтобы токены сотрудников и
   клиентов не были взаимозаменяемы (в payload JWT добавь поле "type": "staff"/"client"
   и проверяй его в каждой из двух deps-функций).
4. app/routers/auth.py — добавить POST /auth/client/register (создаёт Client с
   is_registered=True либо, если email совпадает с уже существующим клиентом без
   пароля — привязывает пароль к нему, спроси уточнение в коде комментарием, если
   это неочевидно как решить), POST /auth/client/login, GET /auth/client/me.
5. Alembic-миграция для новых полей Client.

Не трогать: роутеры hotels/carriers/tours/payments/reports — они остаются
доступны только сотрудникам (get_current_staff), клиентам туда доступа не даём
на этом этапе.

Готово, когда: клиент может зарегистрироваться и получить токен; этот токен
НЕ проходит проверку get_current_staff (и наоборот); GET /auth/client/me отдаёт
данные клиента.
```

### B2. Flutter: вход клиента + "Мои бронирования"

```
Контекст: см. AuthProvider из этапа A2 (это авторизация сотрудников, отдельная
от клиентской). Нужен параллельный, отдельный ClientAuthProvider — не смешивай
токены сотрудника и клиента в одном хранилище (разные ключи в secure storage,
например "staff_token" и "client_token").

Backend: POST /auth/client/register, POST /auth/client/login, GET /auth/client/me,
GET /bookings (уже существует, но верни туда фильтрацию — см. следующий шаг B3
про доступ клиента к своим бронированиям, если backend для этого ещё не готов —
сначала сверься, что там сделано).

Задача:
1. lib/models/client_account.dart — модель для залогиненного клиента.
2. lib/services/client_auth_service.dart — register/login/me к /auth/client/*.
3. lib/providers/client_auth_provider.dart — аналогично AuthProvider из A2,
   но отдельное хранилище токена ("client_token").
4. lib/screens/client_login_screen.dart и client_register_screen.dart —
   простые формы, доступные с витрины (client_mode_screen.dart) через кнопку
   "Войти" / иконку профиля в AppBar.
5. lib/router.dart — маршруты '/client/login', '/client/register',
   '/client/bookings' (заглушка на этом этапе — список бронирований подключим в B3).
6. В client_mode_screen.dart добавить иконку профиля в AppBar: если клиент не
   залогинен — ведёт на '/client/login', если залогинен — на '/client/bookings'.

Не трогать: AuthProvider (сотрудников), lib/router.dart redirect-логику для
'/admin' и других CRUD-путей из этапа A2 — она не должна пересекаться с
клиентскими маршрутами.

Готово, когда: клиент может зарегистрироваться/войти прямо с витрины, токен
клиента хранится отдельно от токена сотрудника, оба могут быть залогинены
одновременно на одном устройстве без конфликта (разумно, если ты тестируешь
и сотрудником, и клиентом с одного телефона).
```

### B3. Самостоятельное бронирование тура

```
Контекст: Booking сейчас создаётся только через POST /bookings, защищённый
get_current_staff (этап A1, шаг 8). Нужно дать залогиненному клиенту создать
заявку на бронирование самостоятельно — но НЕ с тем же уровнем доступа, что
у сотрудника (клиент не должен мочь бронировать от имени другого client_id
или указывать скидку/комиссию).

Задача (backend):
1. app/schemas/booking.py — добавить ClientBookingCreate (tour_id, people_count,
   notes) — без client_id, discount_percent, commission_percent, status
   (все выставляются на бэкенде).
2. app/routers/bookings.py — добавить POST /bookings/self, Depends(get_current_client).
   Внутри: booking_service.build_booking с client_id = текущий клиент (из токена),
   discount_percent=0, commission_percent=10 (дефолт), status="заявка".
3. app/routers/bookings.py — добавить GET /bookings/my, Depends(get_current_client),
   возвращает список бронирований текущего клиента (переиспользуй crud.get_all с
   фильтром по client_id — добавь такой параметр в app/crud/booking.py, например
   get_all(db, client_id: int | None = None)).

Задача (Flutter):
4. lib/services/booking_service.dart — добавить createSelf(tourId, peopleCount, notes)
   -> POST /bookings/self и getMy() -> GET /bookings/my (используют клиентский Dio-клиент
   с client_token — либо заведи отдельный Dio-инстанс для клиентских эндпоинтов, либо
   параметризуй ApiService так, чтобы он мог подставлять либо staff_token, либо
   client_token в зависимости от того, какой раздел приложения делает запрос).
5. В client_mode_screen.dart на карточке тура добавить кнопку "Забронировать":
   если клиент не залогинен — открыть '/client/login'; если залогинен — показать
   диалог с количеством человек и вызвать createSelf(...), после успеха — снек-бар
   и переход на '/client/bookings'.
6. lib/screens/client_bookings_screen.dart — список бронирований клиента (статус,
   даты тура, сумма) через getMy().

Не трогать: POST /bookings (без /self) должен остаться как есть для сотрудников;
build_booking/calc_total_cost в booking_service.py не переписывать — только вызывать
с другими параметрами.

Готово, когда: залогиненный клиент видит кнопку "Забронировать" на туре, после
подтверждения бронирование появляется и на витрине клиента (со статусом "заявка"),
и в админке сотрудника (в общем списке /bookings) — то есть это одна и та же таблица.
```

### B4. Оплата — упрощённая MVP-версия

```
Прежде чем писать промпт для этого шага, реши сам (это бизнес-решение, не
техническое): будете ли вы подключать настоящий платёжный шлюз (эквайринг/
локальная платёжная система) уже на MVP, или на старте достаточно "клиент видит
реквизиты для перевода и сам сообщает, что оплатил, а сотрудник подтверждает"?

Для MVP реалистичнее второй вариант — он не требует договора с платёжным
провайдером и работает уже сейчас поверх того, что есть (GET /bookings/{id}/balance
из этапа A3). Промпт под него:

Контекст: GET /bookings/{id}/balance уже отдаёт total_cost/paid_amount/remaining
(этап A3). Payment создаётся только сотрудником через POST /payments (без
изменений — оставляем это так и на MVP, реальные деньги подтверждает только
человек, не клиент через API).

Задача:
1. Backend: добавить Booking.status значение "ожидает оплаты" в Literal
   (app/schemas/booking.py, из этапа A3) — выставляется автоматически, когда
   клиент создаёт бронирование через /bookings/self (этап B3).
2. Backend: GET /bookings/my (из B3) и GET /bookings/{id}/balance должны быть
   доступны клиенту только для его собственных бронирований — если клиент
   запрашивает balance по чужому booking_id, get_current_client должен вернуть 403.
3. Flutter: на client_bookings_screen.dart (из B3) для каждого бронирования
   показать остаток к оплате (через getBalance) и статичный текст/карточку
   с реквизитами для перевода (номер карты/счёта — просто текстовое поле,
   заполняемое из настроек приложения, не хардкодь в виджете).
4. Flutter: кнопка "Я оплатил" — не создаёт Payment (это может делать только
   сотрудник), а просто переводит статус бронирования в "на проверке" через
   отдельный PATCH /bookings/{id}/status (заведи этот эндпоинт, доступный и
   клиенту для его брони, и сотруднику — с проверкой, что клиент может
   выставить только "на проверке", а не любой статус).

Не трогать: POST /payments и его защиту get_current_staff — реальные платежи
на этом этапе фиксирует только сотрудник вручную, после того как увидел
перевод на счёте.

Готово, когда: клиент видит остаток и реквизиты, может отметить "я оплатил",
сотрудник в админке видит бронирования со статусом "на проверке" и подтверждает
оплату вручную через существующий экран payment_screen.dart.
```

---

## Общие правила, чтобы локальная модель не путалась

1. **Один промпт — один этап.** Не объединяй A1+A2 в одно сообщение, даже если модель "тянет" — это единственная причина, по которой она начинает путать файлы между собой.
2. **Начинай новый чат/контекст на каждый этап**, не продолжай в том же окне, где до этого правился другой этап — старый контекст тянет за собой файлы, которые уже не актуальны.
3. Перед промптом вставляй **только файлы из "Контекст"** этого этапа — не весь `lib/` и не весь `app/`.
4. После каждого этапа — **сам** прогони `flutter analyze` / `pytest` (если тесты есть) или хотя бы запусти приложение, прежде чем переходить к следующему промпту. Не давай следующий этап, если предыдущий не скомпилировался.
5. Секция "Не трогать" в каждом промпте — не формальность, у слабых локальных моделей есть тенденция "заодно причесать" соседний код. Если увидишь правки за пределами списка задач — откатывай именно их, не весь ответ.
