import 'package:flutter/material.dart';

import '../neo_colors.dart';
import '../neo_radius.dart';
import '../neo_shadows.dart';
import '../neo_typography.dart';

/// Input field with 2px border + small offset shadow. Focus switches the
/// shadow to gold.
class NeoInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const NeoInput({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<NeoInput> createState() => _NeoInputState();
}

class _NeoInputState extends State<NeoInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = (widget.errorText ?? '').isNotEmpty;
    final shadow = hasError
        ? NeoShadows.danger(context)
        : (_focusNode.hasFocus ? NeoShadows.gold(context) : NeoShadows.sm(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: NeoTypography.label(color: NeoColors.inkMid(context)),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: NeoColors.surface(context),
            borderRadius: NeoRadius.borderMd,
            border: Border.all(color: NeoColors.border(context), width: 2),
            boxShadow: shadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(
                    color: NeoColors.inkMid(context),
                    size: 18,
                  ),
                  child: widget.prefixIcon!,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  style: NeoTypography.body(color: NeoColors.ink(context)),
                  cursorColor: NeoColors.gold(context),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: widget.placeholder,
                    hintStyle: NeoTypography.body(color: NeoColors.inkLow(context)),
                  ),
                ),
              ),
              if (widget.suffixIcon != null) ...[
                const SizedBox(width: 10),
                IconTheme.merge(
                  data: IconThemeData(
                    color: NeoColors.inkMid(context),
                    size: 18,
                  ),
                  child: widget.suffixIcon!,
                ),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: NeoTypography.caption(color: NeoColors.danger(context)),
          ),
        ] else if ((widget.helper ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: NeoTypography.caption(color: NeoColors.inkLow(context)),
          ),
        ],
      ],
    );
  }
}
