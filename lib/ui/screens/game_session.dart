import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/rules.dart';
import '../../l10n/localized_widgets.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../widgets/dialogs.dart';
import 'results_screens.dart';

/// Cierre común de partida: una sola finalización por sesión.
mixin GameSession<W extends StatefulWidget> on State<W> {
  String session = '';
  int get pairsCount => 4;
  int? get resultMaxScore => null;
  String? get resultMessage => null;
  bool finishing = false;
  GameId get gameId;

  /// Un juego de la versión completa sin derecho no crea sesión: vuelve atrás
  /// y abre «Pide ayuda a un adulto» (la tarjeta ya lo evita; esto es la
  /// segunda comprobación de las reglas).
  Future<bool> beginSession() async {
    final c = AppScope.read(context);
    final s = await c.beginGame(gameId, pairs: pairsCount);
    if (!mounted) {
      if (s != null) c.cancelActivity(s);
      return false;
    }
    session = s ?? '';
    if (s == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        nav.pop();
        if (!c.canPlay(gameId)) {
          showAskAdult(nav.context);
        } else {
          AppScope.feedbackOf(nav.context).play(Sfx.blocked);
          ScaffoldMessenger.of(nav.context).showSnackBar(
            SnackBar(
              content: LText(
                c.gameBlocked ?? 'No se pudo guardar el inicio de la partida.',
              ),
            ),
          );
        }
      });
    }
    return s != null;
  }

  Future<void> complete(int score) async {
    if (finishing) return;
    finishing = true;
    final c = AppScope.read(context);
    final receipt = await commitOrRecover<Receipt>(
      context,
      () => c.finishGame(session, gameId, score),
    );
    if (!mounted) return;
    if (receipt != null) {
      final fx = AppScope.feedbackOf(context);
      fx.play(Sfx.coins);
      replaceScreen(
        context,
        GameResultScreen(
          game: gameId,
          receipt: receipt,
          maxScore: resultMaxScore,
          message: resultMessage,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void cancel() => AppScope.read(context).cancelActivity(session);
}
