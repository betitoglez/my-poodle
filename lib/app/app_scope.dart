import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'feedback.dart';

/// Acceso al estado compartido desde widgets.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required this.feedback,
    required super.child,
  }) : super(notifier: controller);

  final FeedbackService feedback;

  /// Escucha cambios del estado confirmado.
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Lectura sin suscripción (para intenciones en callbacks).
  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static FeedbackService feedbackOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.feedback;
}
