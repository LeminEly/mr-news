import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 
// APP COLORS
// 

class AppColors {
  AppColors._();

  // PRIMARY 
  static const Color primary        = Color(0xFF00C8A0); // vert mauritanien
  static const Color primaryDark    = Color(0xFF00A082);
  static const Color primaryLight   = Color(0xFF4DDFC4);
  static const Color primarySurface = Color(0xFFE6FAF6); // bg léger primary

  // SECONDARY 
  static const Color secondary      = Color(0xFF1A6B3C); // vert drapeau MR
  static const Color secondaryDark  = Color(0xFF0D4A28);
  static const Color secondaryLight = Color(0xFF2E9456);

  // ACCENT 
  static const Color accent         = Color(0xFFD4AF37); // or drapeau MR
  static const Color accentDark     = Color(0xFFB8960C);
  static const Color accentLight    = Color(0xFFE8CC6A);

  // NEUTRALS 
  static const Color background     = Color(0xFFF8FAFB);
  static const Color backgroundDark = Color(0xFF0F1318);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceDark    = Color(0xFF1C2330);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // TEXT 
  static const Color textPrimary    = Color(0xFF1A2030);
  static const Color textSecondary  = Color(0xFF64748B);
  static const Color textTertiary   = Color(0xFF94A3B8);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);
  static const Color textOnDark     = Color(0xFFE2E8F0);

  // BORDERS
  static const Color border         = Color(0xFFE2E8F0);
  static const Color borderDark     = Color(0xFF1E2A38);
  static const Color divider        = Color(0xFFF1F5F9);

  // STATUS
  static const Color success        = Color(0xFF10B981);
  static const Color successLight   = Color(0xFFD1FAE5);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorLight     = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF3B82F6);
  static const Color infoLight      = Color(0xFFDBEAFE);

  // AGENCY STATUS COLORS 
  static const Color statusPending  = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusSuspended= Color(0xFF6B7280);

  // CATEGORY COLORS 
  static const Color catPolitique     = Color(0xFFEF4444);
  static const Color catEconomie      = Color(0xFFF59E0B);
  static const Color catSport         = Color(0xFF10B981);
  static const Color catTechno        = Color(0xFF3B82F6);
  static const Color catSociete       = Color(0xFF8B5CF6);
  static const Color catSante         = Color(0xFFEC4899);
  static const Color catCulture       = Color(0xFFF97316);
  static const Color catInternational = Color(0xFF06B6D4);

  // EMOJI REACTION COLORS
  static const Color emojiLike  = Color(0xFF3B82F6); // 👍 bleu
  static const Color emojiWow   = Color(0xFFF59E0B); // 😮 jaune
  static const Color emojiSad   = Color(0xFF8B5CF6); // 😢 violet
  static const Color emojiAngry = Color(0xFFEF4444); // 😡 rouge
  static const Color emojiFire  = Color(0xFFF97316); // 🔥 orange

  // DARK MODE VARIANTS
  static const Color darkBackground  = Color(0xFF0A0C10);
  static const Color darkSurface     = Color(0xFF0F1318);
  static const Color darkSurface2    = Color(0xFF151A22);
  static const Color darkBorder      = Color(0xFF1E2A38);
}

// 
// APP TEXT STYLES
// 

class AppTextStyles {
  AppTextStyles._();

  // FONT FAMILIES 
  // Cairo    → pour l'arabe (RTL)
  // Poppins  → pour le français (LTR)

  static const String fontAr = 'Cairo';
  static const String fontFr = 'Poppins';

  // DISPLAY
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // HEADLINES
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // BODY
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // LABELS
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ARTICLE TITLE (spécial feed)
  static const TextStyle articleTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.45,
    letterSpacing: -0.1,
  );

  static const TextStyle articleTitleAr = TextStyle(
    fontFamily: fontAr,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  // META (date, source, etc.)
  static const TextStyle meta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textTertiary,
  );

  // BUTTON TEXTS
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

//
// APP SPACING
//

class AppSpacing {
  AppSpacing._();

  static const double xxs  = 2.0;
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Padding standards
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xxl,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
}

//
// APP BORDER RADIUS
//

class AppRadius {
  AppRadius._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static const BorderRadius cardRadius    = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius chipRadius    = BorderRadius.all(Radius.circular(full));
  static const BorderRadius imageRadius   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius bottomSheet   = BorderRadius.vertical(top: Radius.circular(xxl));
}

//
// APP SHADOWS
// 

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
}

//
// APP THEME DATA
//

class AppTheme {
  AppTheme._();

  // LIGHT THEME
  static ThemeData light({String fontFamily = AppTextStyles.fontFr}) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontFamily: fontFamily,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.buttonLarge.copyWith(fontFamily: fontFamily),
          elevation: 0,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.buttonLarge.copyWith(fontFamily: fontFamily),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonMedium.copyWith(fontFamily: fontFamily),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
          fontFamily: fontFamily,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontFamily: fontFamily,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primarySurface,
        labelStyle: AppTextStyles.labelMedium.copyWith(fontFamily: fontFamily),
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        padding: AppSpacing.chipPadding,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          fontFamily: fontFamily,
          color: Colors.white,
        ),
      ),
    );
  }

  // DARK THEME
  static ThemeData dark({String fontFamily = AppTextStyles.fontFr}) {
    return light(fontFamily: fontFamily).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textOnDark,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
