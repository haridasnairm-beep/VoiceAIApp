import 'package:flutter/material.dart';

/// Preset folder colors (10 options).
const folderPresetColors = <Color>[
  Color(0xFF1E88E5), // Blue (default)
  Color(0xFF43A047), // Green
  Color(0xFFE53935), // Red
  Color(0xFFFB8C00), // Orange
  Color(0xFF8E24AA), // Purple
  Color(0xFF00ACC1), // Teal
  Color(0xFFFDD835), // Yellow
  Color(0xFF6D4C41), // Brown
  Color(0xFF546E7A), // Blue Grey
  Color(0xFFEC407A), // Pink
];

/// Default folder color when none is selected.
const defaultFolderColor = Color(0xFF1E88E5);

/// Returns the Color for a folder's colorValue, or the default.
Color folderColor(int? colorValue) {
  if (colorValue == null) return defaultFolderColor;
  return Color(colorValue);
}

/// Inline color picker row for folder creation/edit dialogs.
class FolderColorPicker extends StatelessWidget {
  final int? selectedColorValue;
  final ValueChanged<int> onColorSelected;

  const FolderColorPicker({
    super.key,
    this.selectedColorValue,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: folderPresetColors.map((color) {
        final colorInt = color.toARGB32();
        final isSelected = colorInt == selectedColorValue ||
            (selectedColorValue == null && color == defaultFolderColor);
        return GestureDetector(
          onTap: () => onColorSelected(colorInt),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2.5)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
