import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? icon;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  // New, all optional so every existing call site keeps compiling unchanged.
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.validator,
    this.prefix,
    this.suffix,
    this.autofillHints,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enabled = true,
    this.autovalidateMode,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: widget.enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autocorrect: widget.autocorrect,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          autovalidateMode: widget.autovalidateMode,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix ??
                (widget.icon != null
                    ? Icon(widget.icon, color: AppColors.primary, size: 20)
                    : null),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
