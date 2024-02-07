import 'package:flutter/material.dart';

class SelectableCard extends StatelessWidget {
  final bool isSelected;
  final void Function()? onSelected;
  final Widget? _title;
  final Widget? _leading;
  final Widget? _trailing;

  const SelectableCard({
    required this.isSelected,
    this.onSelected,
    Widget? leading,
    Widget? title,
    Widget? trailing,
    super.key,
  })  : _leading = leading,
        _title = title,
        _trailing = trailing;

  ShapeBorder _buildBorder(BuildContext context, bool outlined) {
    return RoundedRectangleBorder(
      side: outlined ? BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.6) : BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha((0.5 * 255).toInt()),
      shape: _buildBorder(context, isSelected),
      child: InkWell(
        onTap: isSelected ? null : onSelected,
        customBorder: _buildBorder(context, false),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (_leading != null) _leading,
              if (_title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _title,
                ),
              const Spacer(),
              if (_trailing != null) _trailing,
            ],
          ),
        ),
      ),
    );
  }
}
