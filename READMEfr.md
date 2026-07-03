# Travel Agency — Frontend (Flutter)

## Стек
- Flutter 3.35+ / Dart 3.9+
- Provider — управление состоянием
- GoRouter — навигация
- Dio — HTTP-клиент
- fl_chart — графики в отчётах

## Запуск

```bash
flutter pub get
flutter run -d chrome        # веб
flutter run -d <device_id>   # мобильное устройство/эмулятор
```

### Настройка адреса backend

Отредактируйте `kApiBaseUrl` в `lib/services/api_service.dart`:

- Веб / Desktop: `http://localhost:8000`
- Android-эмулятор: `http://10.0.2.2:8000`
- Физическое устройство: `http://<IP-машины-с-backend>:8000`

## Структура

```
lib/
├── models/       # Dart-модели (fromJson/toJson)
├── services/     # Dio-клиенты по сущностям
├── providers/    # ChangeNotifier — состояние экранов
├── screens/      # экраны, сгруппированы по разделам
├── widgets/      # переиспользуемые виджеты
├── theme/        # тёмная glassmorphism-тема (AppColors, AppTheme, GlassCard)
├── router.dart   # маршруты GoRouter
└── main.dart     # точка входа
```

## Реализованные экраны

| Экран | Функциональность |
|---|---|
| `HomeScreen` | навигация по разделам |
| `TourListScreen` / `TourFormScreen` | список с фильтром (страна/цена) + поиск, CRUD-форма |
| `ClientListScreen` | список с поиском по ФИО/телефону/email, CRUD через диалог |
| `BookingListScreen` / `BookingFormScreen` | список бронирований, форма с авторасчётом суммы |
| `PaymentScreen` | платежи по конкретному бронированию |
| `ReportsScreen` | вкладки: продажи, популярные направления (график), доход агентства |
| `HotelListScreen` / `CarrierListScreen` | CRUD-справочники |

## Что доделать под конкретную сдачу

- Добавить полноценную форму редактирования клиента с валидацией дат/паспорта
- Добавить пагинацию для больших списков
- Добавить экран отдельного бронирования (детали + история платежей на одном экране)
- При необходимости — авторизация (JWT), как в ERP-проекте
