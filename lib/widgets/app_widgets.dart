// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

// ─── Text field ───────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? errorText;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: maxLines,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        errorText: errorText,
        errorStyle: GoogleFonts.dmSans(color: AppColors.red, fontSize: 11),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtext;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(),
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text(value,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 20,
                      fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(subtext!,
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    final color = isPaid ? AppColors.green : AppColors.yellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPaid ? Icons.check_circle : Icons.access_time, size: 10, color: color),
        const SizedBox(width: 4),
        Text(status,
            style: GoogleFonts.dmSans(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── App card ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppCard({super.key, required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(borderRadius ?? 14),
        border: Border.all(color: AppColors.border),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Text(subtitle!,
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 12)),
        ]),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          disabledBackgroundColor: (color ?? AppColors.primary).withOpacity(0.4),
        ),
        child: loading
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ]),
      ),
    );
  }
}

// ─── Offline banner ───────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      color: AppColors.yellow.withOpacity(0.15),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 14, color: AppColors.yellow),
        const SizedBox(width: 6),
        Text('Offline — changes will sync when reconnected',
            style: GoogleFonts.dmSans(
                color: AppColors.yellow,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textMuted.withOpacity(0.4), size: 48),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
      ]),
    );
  }
}

// ─── Toast ────────────────────────────────────────────────────────────────────
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
    backgroundColor: error ? AppColors.red : AppColors.surface,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(12),
  ));
}

// ─── Confirm dialog ───────────────────────────────────────────────────────────
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.confirmColor = AppColors.red,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: GoogleFonts.dmSans(
                  color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─── Loading overlay ──────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (loading)
        Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
    ]);
  }
}
