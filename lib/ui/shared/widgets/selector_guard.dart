import 'package:flutter/widgets.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';

class SelectorGuard<T, R> extends StatelessWidget {
  final R? Function(T value) selector;
  final bool Function(R value)? condition;
  final Widget Function(BuildContext context, R value) then;
  final Widget Function(BuildContext context, R? value)? otherwise;

  const SelectorGuard({
    super.key,
    required this.selector,
    required this.then,
    this.condition,
    this.otherwise,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<T, R?>(
      selector: (_, value) => selector(value),
      builder: (context, R? result, _) {
        bool matches = result != null && (condition?.let((it) => it(result)) ?? (result is bool && result || result is! bool));
        return matches ? then(context, result) : otherwise?.call(context, result) ?? const SizedBox.shrink();
      },
    );
  }
}
