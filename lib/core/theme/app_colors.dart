import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Forest & Sage 5-tone palette
  static const Color deepForest = Color(0xFF0F2A1D); // #0F2A1D (Headers & Ink)
  static const Color mossGreen = Color(
    0xFF375534,
  ); // #375534 (Sent Bubbles & Accents)
  static const Color sageGreen = Color(
    0xFF6B9071,
  ); // #6B9071 (Timestamps & Borders)
  static const Color celadonStone = Color(
    0xFFAEC3B0,
  ); // #AEC3B0 (Received Bubbles & Cards)
  static const Color swatchCream = Color(
    0xFFE3EED4,
  ); // #E3EED4 (Original 5th Swatch)

  // Calmed, low-intensity background canvas (soft whisper-sage tint)
  static const Color paleSageCream = Color(
    0xFFF5F8F1,
  ); // Soft neutral sage-white canvas
  static const Color extraLight = Color(0xFFFAFCF8); // Crisp soft card surface

  // Backward-compatible aliases for existing screen references
  static const Color deepEspresso = deepForest;
  static const Color chestnut = mossGreen;
  static const Color warmTaupe = sageGreen;
  static const Color greigeStone = celadonStone;
  static const Color softCream = paleSageCream;

  // Semantic aliases
  static const Color primary = deepForest;
  static const Color primaryAccent = mossGreen;
  static const Color muted = sageGreen;
  static const Color surface = paleSageCream;
  static const Color surfaceLight = extraLight;
  static const Color card = celadonStone;

  // Bubble colors
  static const Color sentBubble = mossGreen;
  static const Color receivedBubble = celadonStone;

  // Text on bubbles
  static const Color sentBubbleText = Color(0xFFF5F8F1);
  static const Color receivedBubbleText = deepForest;

  // Badge / FAB
  static const Color unreadBadge = mossGreen;
  static const Color fab = mossGreen;

  // Borders, timestamps, muted labels
  static const Color border = sageGreen;
  static const Color timestamp = sageGreen;
  static const Color mutedLabel = sageGreen;

  // White for contrast where needed
  static const Color white = Color(0xFFFFFFFF);
}
