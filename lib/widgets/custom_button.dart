// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? elevation;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final TextStyle? textStyle;
  final OutlinedBorder? shape;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
    this.elevation,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.textStyle,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveButtonColor = color ?? theme.colorScheme.primary;
    final Color effectiveTextColor = textColor ?? theme.colorScheme.onPrimary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveTextColor,
        padding: padding,
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
        textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ).copyWith(
        // Manejar el estado deshabilitado visualmente si está cargando
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled) || isLoading) {
              return effectiveButtonColor.withOpacity(0.5);
            }
            return effectiveButtonColor; // Use the component's default.
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
             if (states.contains(WidgetState.disabled) || isLoading) {
              return effectiveTextColor.withOpacity(0.7);
            }
            return effectiveTextColor;
          }
        )
      ),
      onPressed: isLoading ? null : onPressed, // Deshabilitar si está cargando
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: (textStyle?.fontSize ?? 16) * 1.2),
                  const SizedBox(width: 8),
                ],
                Text(text),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: (textStyle?.fontSize ?? 16) * 1.2),
                ],
              ],
            ),
    );
  }
}

// Ejemplo de un botón secundario/outlined usando el CustomButton como base
class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color; // Color del borde y texto
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final TextStyle? textStyle;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.textStyle,
  });

   @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveColor = color ?? theme.colorScheme.primary;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        padding: padding,
        side: BorderSide(color: effectiveColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ).copyWith(
         side: WidgetStateProperty.resolveWith<BorderSide?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled) || isLoading) {
              return BorderSide(color: effectiveColor.withOpacity(0.5), width: 1.5);
            }
            return BorderSide(color: effectiveColor, width: 1.5);
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
             if (states.contains(WidgetState.disabled) || isLoading) {
              return effectiveColor.withOpacity(0.7);
            }
            return effectiveColor;
          }
        )
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: (textStyle?.fontSize ?? 16) * 1.2),
                  const SizedBox(width: 8),
                ],
                Text(text),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: (textStyle?.fontSize ?? 16) * 1.2),
                ],
              ],
            ),
    );
  }
}
