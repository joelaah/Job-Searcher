import 'package:flutter/material.dart';

class AppColors {
  // ── Abyssal Marine Base & Structural Surfaces ──
  static const Color surface = Color(0xFF0B141B); // Base Deep Void Surface
  static const Color surfaceContainerLowest = Color(0xFF060F15);
  static const Color surfaceContainerLow = Color(0xFF141D23);
  static const Color surfaceContainer = Color(0xFF182127);
  static const Color surfaceContainerHigh = Color(0xFF222B32);
  static const Color surfaceContainerHighest = Color(0xFF2D363D);
  static const Color surfaceVariant = Color(0xFF2D363D);
  static const Color surfaceDim = Color(0xFF0B141B);
  static const Color surfaceBright = Color(0xFF313A41);

  // ── Legacy Aliases for Surface ──
  static const Color background = Color(0xFF0B141B); // Midnight Marine Abyss
  static const Color surfaceElevated = Color(0xFF141D23); // Elevated Marine Card
  static const Color surfaceCard = Color(0xFF182127); // Bento Surface
  static const Color surfaceBorder = Color(0xFF222B32); // Subtle Border

  // ── Primaries & Accents: Cyber Cyan & Luminous Emerald ──
  static const Color primary = Color(0xFF4CD7F6); // Active cyan glow / readouts
  static const Color primaryContainer = Color(0xFF06B6D4); // CTA fill
  static const Color onPrimary = Color(0xFF003640);
  static const Color onPrimaryContainer = Color(0xFF00424F);
  static const Color primaryGlow = Color(0x334CD7F6);

  static const Color secondary = Color(0xFF4EDEA3); // Luminous emerald LED
  static const Color secondaryContainer = Color(0xFF00A572);
  static const Color onSecondary = Color(0xFF003824);
  static const Color onSecondaryContainer = Color(0xFF00311F);
  static const Color secondaryGlow = Color(0x334EDEA3);

  static const Color tertiary = Color(0xFF89CEFF);
  static const Color tertiaryContainer = Color(0xFF2BB0F5);
  static const Color onTertiary = Color(0xFF00344D);
  static const Color onTertiaryContainer = Color(0xFF00405E);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color cyanAccent = Color(0xFF06B6D4); // Cyber Cyan
  static const Color emeraldAccent = Color(0xFF4EDEA3); // Luminous Emerald
  static const Color mintAccent = Color(0xFF34D399); // Crisp Mint
  static const Color marineBlue = Color(0xFF0EA5E9); // Electric Marine Blue

  // ── Status & Match Indicators ──
  static const Color matchHigh = Color(0xFF4EDEA3); // Emerald (90%+)
  static const Color matchMedium = Color(0xFF4CD7F6); // Electric Sky Cyan (75-89%)
  static const Color matchLow = Color(0xFFF59E0B); // Amber Warning
  static const Color matchBadgeBg = Color(0xFF042F24); // Deep Forest Green Badge
  static const Color accentRed = Color(0xFFFFB4AB); // Error / Destructive Crimson

  // ── Typography & Slates ──
  static const Color onSurface = Color(0xFFDAE4ED); // Crisp icy text
  static const Color onSurfaceVariant = Color(0xFFBCC9CD); // Muted slate text
  static const Color textPrimary = Color(0xFFDAE4ED); // Icy Mint-White (extremely crisp)
  static const Color textSecondary = Color(0xFFBCC9CD); // Soft Slate Gray
  static const Color textMuted = Color(0xFF869397); // Muted Marine Slate

  // ── Borders & Dividers ──
  static const Color outline = Color(0xFF869397);
  static const Color outlineVariant = Color(0xFF3D494C);
  static const Color borderSubtle = Color(0xFF182127);
  static const Color borderHighlight = Color(0xFF2D363D);

  // ── Bento Grid Styling Tokens ──
  static const Color bentoCard = Color(0xFF141D23);
  static const Color bentoCardElevated = Color(0xFF182127);
  static const Color bentoBorder = Color(0xFF222B32);
  static const Color bentoBorderHover = Color(0xFF4EDEA3);
  static const Color bentoGlowPrimary = Color(0x304CD7F6);
  static const Color bentoGlowEmerald = Color(0x304EDEA3);
  static const Color bentoGlowCyan = Color(0x3006B6D4);
  static const Color bentoGlowAmber = Color(0x30F59E0B);

  // ── Bento Gradients: Green & Blue Fusion ──
  static const LinearGradient bentoHeroBorderGradient = LinearGradient(
    colors: [Color(0xFF4EDEA3), Color(0xFF4CD7F6), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bentoCardGradient = LinearGradient(
    colors: [Color(0xFF141D23), Color(0xFF0B141B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bentoGlassGradient = LinearGradient(
    colors: [Color(0x184EDEA3), Color(0x064CD7F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF4EDEA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldBlueGradient = LinearGradient(
    colors: [Color(0xFF4EDEA3), Color(0xFF4CD7F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0E2234), Color(0xFF0B141B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient matchGlowGradient = LinearGradient(
    colors: [Color(0xFF4EDEA3), Color(0xFF4CD7F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
