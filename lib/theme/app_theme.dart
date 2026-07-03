import 'package:flutter/material.dart';

/// Палитра «мягкий тревел».
///
/// Ушли от неонового cyberpunk-стекла: оно давало резкие полупрозрачные
/// плашки с тонкими рамками — именно это читалось старомодно. Теперь плотные
/// поверхности, мягкие тени вместо границ, тёплая бумажная база и два
/// природных акцента — терракота (закат) и глубокая бирюза (океан).
abstract class AppLightColors {
  static const background = Color(0xFFFAF7F2); // тёплая бумага
  static const backgroundAlt = Color(0xFFF2EBE1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F1E9); // вторичные плашки, поля ввода
  static const border = Color(0x14231F1A); // почти невидимый волосок
  static const borderStrong = Color(0x2E231F1A);
  static const accentPrimary = Color(0xFFC2603C); // терракота
  static const accentSecondary = Color(0xFF12706A); // глубокая бирюза
  static const textPrimary = Color(0xFF1F1C18);
  static const textSecondary = Color(0xFF7A736A);
  static const success = Color(0xFF2E7D5B);
  static const warning = Color(0xFFB8792A);
  static const danger = Color(0xFFC0492F);
  static const shadow = Color(0xFF3D3226);
}

/// Тёмная тема — не инверсия, а «вечер»: тёплый почти-чёрный вместо синего
/// угля, те же акценты, но осветлённые до читаемого контраста.
abstract class AppColors {
  static const background = Color(0xFF15120F);
  static const backgroundAlt = Color(0xFF1E1A16);
  static const surface = Color(0xFF231F1A);
  static const surfaceAlt = Color(0xFF2C2721);
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x2EFFFFFF);
  static const accentPrimary = Color(0xFFE58B62); // терракота на тёмном
  static const accentSecondary = Color(0xFF48C4B7); // бирюза на тёмном
  static const textPrimary = Color(0xFFF4EFE7);
  static const textSecondary = Color(0xFFA79E92);
  static const success = Color(0xFF57C48C);
  static const warning = Color(0xFFE0A64C);
  static const danger = Color(0xFFEB7259);
  static const shadow = Color(0xFF000000);
}

/// Единые радиусы. Крупные скругления — половина «современного» вида.
abstract class AppRadius {
  static const card = 24.0;
  static const control = 16.0;
  static const pill = 999.0;
  static const sheet = 28.0;
}

class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppLightColors.background,
        surface: AppLightColors.surface,
        surfaceAlt: AppLightColors.surfaceAlt,
        border: AppLightColors.border,
        primary: AppLightColors.accentPrimary,
        secondary: AppLightColors.accentSecondary,
        danger: AppLightColors.danger,
        textPrimary: AppLightColors.textPrimary,
        textSecondary: AppLightColors.textSecondary,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        border: AppColors.border,
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        danger: AppColors.danger,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color primary,
    required Color secondary,
    required Color danger,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
      ),
      splashColor: primary.withValues(alpha: 0.07),
      highlightColor: primary.withValues(alpha: 0.04),
      // Крупнее и с более плотным трекингом на заголовках — так текст
      // читается как современная типографика, а не как дефолт Material.
      textTheme: base.textTheme
          .apply(bodyColor: textPrimary, displayColor: textPrimary)
          .copyWith(
            displaySmall: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: textPrimary),
            headlineMedium: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: textPrimary),
            headlineSmall: TextStyle(
                fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: textPrimary),
            titleLarge: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: textPrimary),
            titleMedium: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
            bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: textPrimary),
            bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textPrimary),
            bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      // Поля без видимой рамки в покое — она появляется только на фокусе.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        helperStyle: TextStyle(color: textSecondary, fontSize: 11.5),
        prefixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textSecondary.withValues(alpha: 0.18),
          disabledForegroundColor: textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(), // pill вместо прямоугольника
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border == AppColors.border ? AppColors.borderStrong : AppLightColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: textPrimary, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark ? surfaceAlt : const Color(0xFF2A241D),
        contentTextStyle: const TextStyle(color: Color(0xFFF4EFE7), fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(fontSize: 14, height: 1.5, color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : textSecondary),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : surfaceAlt),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : textSecondary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

/// Цвета, зависящие от темы. Использовать ВЕЗДЕ вместо AppColors.* напрямую
/// для текста/фонов/границ — тогда светлая тема тоже будет выглядеть цельно.
class ThemeColors {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;
  final Brightness brightness;

  const ThemeColors({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Совместимость со старым кодом: раньше поверхности были полупрозрачным
  /// «стеклом». Теперь это обычные плотные поверхности.
  Color get surfaceGlass => surfaceAlt;
  Color get surfaceGlassStrong => surfaceAlt;

  /// Мягкая многослойная тень — то, что заменило рамки вокруг карточек.
  List<BoxShadow> cardShadow({bool raised = false}) => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.45 : 0.06),
          blurRadius: raised ? 28 : 16,
          offset: Offset(0, raised ? 12 : 5),
        ),
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.25 : 0.03),
          blurRadius: raised ? 6 : 3,
          offset: const Offset(0, 1),
        ),
      ];

  static const _dark = ThemeColors(
    background: AppColors.background,
    backgroundAlt: AppColors.backgroundAlt,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    accentPrimary: AppColors.accentPrimary,
    accentSecondary: AppColors.accentSecondary,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    shadow: AppColors.shadow,
    brightness: Brightness.dark,
  );

  static const _light = ThemeColors(
    background: AppLightColors.background,
    backgroundAlt: AppLightColors.backgroundAlt,
    surface: AppLightColors.surface,
    surfaceAlt: AppLightColors.surfaceAlt,
    border: AppLightColors.border,
    borderStrong: AppLightColors.borderStrong,
    accentPrimary: AppLightColors.accentPrimary,
    accentSecondary: AppLightColors.accentSecondary,
    textPrimary: AppLightColors.textPrimary,
    textSecondary: AppLightColors.textSecondary,
    success: AppLightColors.success,
    warning: AppLightColors.warning,
    danger: AppLightColors.danger,
    shadow: AppLightColors.shadow,
    brightness: Brightness.light,
  );

  static ThemeColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Основная карточка приложения: плотная поверхность, крупное скругление,
/// мягкая тень. Пришла на смену AppCard — полупрозрачное стекло с рамкой
/// и было главным источником «старомодности».
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadius.card,
    this.color,

    /// Приподнятая карточка — для акцентных блоков (формы входа, итоги).
    this.raised = false,

    /// Реагировать ли на наведение курсора. Для статичных панелей не нужно.
    this.interactive = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;
  final bool raised;
  final bool interactive;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);
    final lifted = widget.raised || (_hovering && widget.onTap != null);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
          0, _hovering && widget.onTap != null ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: widget.color ?? colors.surface,
        borderRadius: radius,
        boxShadow: colors.cardShadow(raised: lifted),
        // В тёмной теме одной тени мало — поверхности сливаются с фоном,
        // поэтому добавляем едва заметный контур.
        border: colors.isDark ? Border.all(color: colors.border) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(20),
            child: widget.child,
          ),
        ),
      ),
    );

    if (!widget.interactive || widget.onTap == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: card,
    );
  }
}

/// Компактная «таблетка» — статусы, теги, счётчики. Один вид на всё приложение.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
    this.compact = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: fg),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Заголовок секции — мелкий, разреженный, приглушённый.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: ThemeColors.of(context).textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
