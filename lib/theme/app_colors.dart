import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Green & Blue Marine Backgrounds ──
  static const Color background = Color(0xFF040C12); // Midnight Marine Abyss
  static const Color surface = Color(0xFF081622); // Deep Ocean Teal Slate
  static const Color surfaceElevated = Color(0xFF0E2234); // Elevated Marine Card
  static const Color surfaceCard = Color(0xFF091A27); // Rich Navy-Teal Bento Surface
  static const Color surfaceBorder = Color(0xFF13354B); // Subtle Teal-Cyan Border

  // ── Primaries & Accents: Dark Green & Electric Blue ──
  static const Color primary = Color(0xFF0EA5E9); // Electric Ocean Blue
  static const Color primaryGlow = Color(0x330EA5E9);
  static const Color secondary = Color(0xFF10B981); // Luminous Emerald Green
  static const Color secondaryGlow = Color(0x3310B981);
  static const Color cyanAccent = Color(0xFF06B6D4); // Cyber Cyan
  static const Color emeraldAccent = Color(0xFF059669); // Forest Emerald
  static const Color mintAccent = Color(0xFF34D399); // Crisp Mint
  static const Color marineBlue = Color(0xFF0284C7); // Deep Marine Blue

  // ── Status & Match Indicators ──
  static const Color matchHigh = Color(0xFF10B981); // Emerald (90%+)
  static const Color matchMedium = Color(0xFF38BDF8); // Electric Sky Cyan (75-89%)
  static const Color matchLow = Color(0xFFF59E0B); // Amber Warning
  static const Color matchBadgeBg = Color(0xFF042F24); // Deep Forest Green Badge
  static const Color accentRed = Color(0xFFEF4444); // Error / Destructive Crimson


  // ── Text Hierarchy ──
  static const Color textPrimary = Color(0xFFF0FDF4); // Icy Mint-White (extremely crisp)
  static const Color textSecondary = Color(0xFF94A3B8); // Soft Slate Gray
  static const Color textMuted = Color(0xFF5B788C); // Muted Marine Slate

  // ── Borders & Dividers ──
  static const Color borderSubtle = Color(0xFF0E2536);
  static const Color borderHighlight = Color(0xFF1C4964);

  // ── Bento Grid Styling Tokens ──
  static const Color bentoCard = Color(0xFF081824);
  static const Color bentoCardElevated = Color(0xFF0D2538);
  static const Color bentoBorder = Color(0xFF12344A);
  static const Color bentoBorderHover = Color(0xFF10B981);
  static const Color bentoGlowPrimary = Color(0x300EA5E9);
  static const Color bentoGlowEmerald = Color(0x3010B981);
  static const Color bentoGlowCyan = Color(0x3006B6D4);
  static const Color bentoGlowAmber = Color(0x30F59E0B);

  // ── Bento Gradients: Green & Blue Fusion ──
  static const LinearGradient bentoHeroBorderGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bentoCardGradient = LinearGradient(
    colors: [Color(0xFF0A1F2C), Color(0xFF06141F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bentoGlassGradient = LinearGradient(
    colors: [Color(0x1810B981), Color(0x060EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldBlueGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF042728), Color(0xFF040C12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient matchGlowGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
