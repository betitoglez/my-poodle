import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/save_codec.dart';
import '../data/save_store.dart';
import '../data/storage_backend.dart';
import '../domain/appearance.dart';
import '../domain/balance.dart';
import '../domain/entitlements.dart';
import '../domain/food.dart';
import '../domain/needs_clock.dart';
import '../domain/pet_name.dart';
import '../domain/pet_state.dart';
import '../domain/rules.dart';
import '../domain/sessions.dart';
import '../game/pet/appearance_catalog.dart';
import '../store/store_controller.dart';

enum BootStatus { loading, adoption, ready, ioError, corrupted, futureSchema }

/// Resultado de una intención que guarda en disco.
sealed class ActionResult<T> {
  const ActionResult();
}

class Done<T> extends ActionResult<T> {
  const Done(this.value);
  final T value;
}

/// No se pudo guardar: el candidato queda pendiente para reintentar.
class SaveFailed<T> extends ActionResult<T> {
  const SaveFailed(this.error);
  final Object error;
}

/// Evento descartado (sesión cancelada o anterior).
class Ignored<T> extends ActionResult<T> {
  const Ignored();
}

class _Pending {
  _Pending(this.candidate, this.onCommitted);
  final PetState candidate;
  final void Function() onCommitted;
}

/// Estado compartido de la app. La UI emite intenciones; aquí se aplican las
/// reglas puras, se serializan escrituras y se publica el estado confirmado.
class AppController extends ChangeNotifier {
  AppController({
    required this.balance,
    required this.looks,
    required SaveStore store,
    required this.clock,
    required this.purchases,
  }) : rules = Rules(balance),
       // ignore: prefer_initializing_formals
       _store = store {
    // El derecho confirmado redibuja candados al instante.
    purchases.addListener(notifyListeners);
  }

  final Balance balance;
  final AppearanceCatalog looks;
  final Clock clock;
  final Rules rules;
  final SessionRegistry sessions = SessionRegistry();

  /// Versión completa: tienda, derecho guardado y flujo de compra.
  final StoreController purchases;

  SaveStore _store;
  SaveStore? _realStore;
  PetState? _realConfirmed;

  BootStatus status = BootStatus.loading;
  String? errorDetail;
  PetState? _confirmed;
  _Pending? _pending;
  bool saving = false;
  Future<void> _tail = Future.value();

  bool demo = false;
  Timer? _ticker;

  SaveStore get store => _store;
  bool get hasPending => _pending != null;

  /// Estado visible: confirmado + paso del tiempo calculado al vuelo (no se
  /// guarda hasta la siguiente acción; recalcular es idempotente).
  PetState? get state {
    final c = _confirmed;
    if (c == null) return null;
    return rules.clock.advance(c, clock.nowUtcSeconds());
  }

  PetState get pet => state!;
  Preferences get prefs => _confirmed?.prefs ?? const Preferences();
  bool get reducedMotion => prefs.reducedMotion;
  PetLook get look => looks.resolve(pet.appearance);

  /// Derecho confirmado (o el de la demostración).
  bool get fullVersion => purchases.full;
  bool canAccess(Tier tier) => purchases.canAccess(tier);
  bool canPlay(GameId game) => canAccess(rules.gameTier(game));

  /// Artículos de [target] que piden la versión completa.
  List<String> lockedIn(Appearance target) =>
      rules.lockedItems(pet, target, fullVersion: fullVersion);

  bool isLocked(String itemId) =>
      !(pet.owned.contains(itemId)) &&
      !canAccess(balance.item(itemId)?.tier ?? Tier.free);

  Future<void> boot() async {
    status = BootStatus.loading;
    errorDetail = null;
    notifyListeners();
    final result = await _store.load();
    switch (result) {
      case LoadEmpty():
        _confirmed = null;
        status = BootStatus.adoption;
      case LoadOk(:final state):
        _confirmed = state;
        status = BootStatus.ready;
      case LoadCorrupted(:final detail):
        errorDetail = detail;
        status = BootStatus.corrupted;
      case LoadFutureSchema(:final version):
        errorDetail = 'versión $version';
        status = BootStatus.futureSchema;
      case LoadIoError(:final detail):
        errorDetail = detail;
        status = BootStatus.ioError;
    }
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_confirmed != null) notifyListeners();
    });
  }

  /// Al volver de segundo plano se recalculan las necesidades.
  void onResumed() => notifyListeners();

  @override
  void dispose() {
    _ticker?.cancel();
    purchases.removeListener(notifyListeners);
    super.dispose();
  }

  // ------------------------------------------------------------ escritura

  Future<T> _serial<T>(Future<T> Function() op) {
    final r = _tail.then((_) => op());
    _tail = r.then((_) {}, onError: (_) {});
    return r;
  }

  Future<ActionResult<T>> _commit<T>(
    PetState candidate,
    T value, {
    void Function()? onCommitted,
  }) {
    return _serial(() async {
      saving = true;
      notifyListeners();
      try {
        await _store.write(candidate);
        _confirmed = candidate;
        _pending = null;
        onCommitted?.call();
        return Done<T>(value);
      } catch (e) {
        _pending = _Pending(candidate, onCommitted ?? () {});
        return SaveFailed<T>(e);
      } finally {
        saving = false;
        notifyListeners();
      }
    });
  }

  /// Reintenta el candidato pendiente. Ante un resultado incierto relee el
  /// último ID confirmado antes de escribir de nuevo.
  Future<bool> retryPending() {
    return _serial(() async {
      final p = _pending;
      if (p == null) return true;
      saving = true;
      notifyListeners();
      try {
        if (await _store.committedId() != p.candidate.lastCommitId) {
          await _store.write(p.candidate);
        }
        _confirmed = p.candidate;
        _pending = null;
        p.onCommitted();
        return true;
      } catch (_) {
        return false;
      } finally {
        saving = false;
        notifyListeners();
      }
    });
  }

  /// Descarta el candidato solo tras verificar lo que hay en disco.
  Future<void> discardPending() {
    return _serial(() async {
      final p = _pending;
      _pending = null;
      if (p == null) return;
      final r = await _store.load();
      if (r is LoadOk) {
        _confirmed = r.state;
        if (r.state.lastCommitId == p.candidate.lastCommitId) p.onCommitted();
      }
      notifyListeners();
    });
  }

  // ------------------------------------------------------------ intenciones

  Future<ActionResult<PetState>> adopt(String rawName) async {
    if (_confirmed != null) return const Ignored();
    final name = PetName.validate(rawName);
    if (name is! ValidName) return const Ignored();
    final s = PetState.adopt(
      validName: name.value,
      nowUtc: clock.nowUtcSeconds(),
      balance: balance,
    );
    final r = await _commit(s, s);
    if (r is Done) status = BootStatus.ready;
    notifyListeners();
    return r;
  }

  String? careBlocked(CareKind kind, {Food food = Food.basic}) =>
      rules.careBlocked(
        pet,
        kind,
        clock.nowUtcSeconds(),
        food: food,
        fullVersion: fullVersion,
      );
  String? get gameBlocked => rules.gameBlocked(pet, clock.nowUtcSeconds());

  String beginActivity(String activityId) {
    final kind = CareKind.values.where((k) => k.name == activityId).firstOrNull;
    if (kind == null || careBlocked(kind) != null || saving || hasPending) {
      return '';
    }
    return sessions.begin(activityId);
  }

  /// Abre la sesión de un minijuego; un juego de la versión completa sin
  /// derecho se rechaza (`requiresFull`) y no crea sesión.
  Future<String?> beginGame(GameId game) => _serial(() async {
    if (!canPlay(game) || gameBlocked != null || hasPending || saving) {
      return null;
    }
    final id = sessions.begin(game.name);
    final candidate = rules.startGame(
      _confirmed!,
      'start-$id',
      clock.nowUtcSeconds(),
    );
    saving = true;
    notifyListeners();
    try {
      await _store.write(candidate);
      _confirmed = candidate;
      return id;
    } catch (_) {
      sessions.cancel(id);
      return null;
    } finally {
      saving = false;
      notifyListeners();
    }
  });

  void cancelActivity(String sessionId) => sessions.cancel(sessionId);

  Future<ActionResult<Receipt>> finishCare(
    String sessionId,
    CareKind kind, {
    Food food = Food.basic,
  }) async {
    final previous = sessions.receiptOf<Receipt>(sessionId);
    if (previous != null) return Done(previous);
    if (!sessions.isOpen(sessionId) ||
        _confirmed == null ||
        saving ||
        hasPending) {
      return const Ignored();
    }
    if (sessions.activityOf(sessionId) != kind.name ||
        careBlocked(kind, food: food) != null) {
      return const Ignored();
    }
    final receipt = rules.finishCare(
      _confirmed!,
      kind,
      sessionId,
      clock.nowUtcSeconds(),
      food: food,
      fullVersion: fullVersion,
    );
    return _commit(
      receipt.after,
      receipt,
      onCommitted: () => sessions.complete(sessionId, receipt),
    );
  }

  Future<ActionResult<Receipt>> finishGame(
    String sessionId,
    GameId game,
    int score,
  ) async {
    final previous = sessions.receiptOf<Receipt>(sessionId);
    if (previous != null) return Done(previous);
    if (!sessions.isOpen(sessionId) ||
        _confirmed == null ||
        saving ||
        hasPending) {
      return const Ignored();
    }
    if (sessions.activityOf(sessionId) != game.name) return const Ignored();
    final Receipt receipt;
    try {
      receipt = rules.finishGame(
        _confirmed!,
        game,
        score,
        sessionId,
        clock.nowUtcSeconds(),
      );
    } on RuleException {
      sessions.cancel(sessionId);
      return const Ignored();
    }
    return _commit(
      receipt.after,
      receipt,
      onCommitted: () => sessions.complete(sessionId, receipt),
    );
  }

  int lookCost(Appearance target) => rules.lookCost(pet, target);

  /// Comprar y usar (o usar gratis lo que ya es propio) en una operación.
  Future<ActionResult<PurchaseOutcome>> applyLook(Appearance target) async {
    if (_confirmed == null) return const Ignored();
    final opId = 'look-${clock.nowUtcSeconds()}-${_confirmed!.revision}';
    final outcome = rules.applyLook(
      _confirmed!,
      target,
      opId,
      clock.nowUtcSeconds(),
      fullVersion: fullVersion,
    );
    return switch (outcome) {
      InsufficientCoins() || RequiresFull() => Done(outcome),
      Purchased(:final receipt) => _commit(receipt.after, outcome),
    };
  }

  Future<ActionResult<Preferences>> updatePrefs(Preferences p) {
    final c = _confirmed!;
    final next = c.copyWith(
      prefs: p,
      revision: c.revision + 1,
      lastCommitId: 'prefs-${clock.nowUtcSeconds()}-${c.revision}',
    );
    return _commit(next, p);
  }

  Future<void> markHintSeen(String key) async {
    if (_confirmed == null || prefs.seenHints.contains(key)) return;
    await updatePrefs(prefs.copyWith(seenHints: {...prefs.seenHints, key}));
  }

  /// Reinicio confirmado desde la zona adulta.
  Future<void> resetGame() => _serial(() async {
    await _store.reset();
    _confirmed = null;
    _pending = null;
    status = BootStatus.adoption;
    notifyListeners();
  });

  // ------------------------------------------------------------ demostración

  /// Entra en un entorno aislado en memoria con una partida de muestra. La
  /// partida normal no se modifica y se restaura al salir.
  void enterDemo() {
    if (demo) return;
    _realStore = _store;
    _realConfirmed = _confirmed;
    _store = SaveStore(MemoryBackend(), SaveCodec(balance));
    final base = PetState.adopt(
      validName: 'Miel',
      nowUtc: clock.nowUtcSeconds(),
      balance: balance,
    );
    _confirmed = base.copyWith(
      coins: 12,
      prefs: _realConfirmed?.prefs ?? const Preferences(),
      lastCommitId: 'demo-1',
    );
    demo = true;
    // La demostración empieza en la versión gratuita, solo en memoria.
    purchases.setDemo(Entitlement.none);
    status = BootStatus.ready;
    notifyListeners();
  }

  void exitDemo() {
    if (!demo) return;
    _store = _realStore!;
    _confirmed = _realConfirmed;
    _realStore = null;
    _realConfirmed = null;
    demo = false;
    purchases.setDemo(null);
    _pending = null;
    status = _confirmed == null ? BootStatus.adoption : BootStatus.ready;
    notifyListeners();
  }

  void _demoSet(PetState Function(PetState) f) {
    if (!demo || _confirmed == null) return;
    _confirmed = f(_confirmed!).copyWith(revision: _confirmed!.revision + 1);
    notifyListeners();
  }

  /// Enferma o cura a la partida de muestra.
  void demoSetSick(bool sick) => _demoSet(
    (s) => sick
        ? s.copyWith(
            sickSinceUtc: clock.nowUtcSeconds(),
            lastSickUtc: clock.nowUtcSeconds(),
          )
        : s.copyWith(cured: true),
  );

  void demoSetCoins(int coins) => _demoSet((s) => s.copyWith(coins: coins));

  void demoLowNeeds() => _demoSet(
    (s) => s.copyWith(
      needs100: {
        Need.satiety: 1200,
        Need.hygiene: 1800,
        Need.mood: 2500,
        Need.energy: 900,
      },
    ),
  );

  void demoFullNeeds() => _demoSet(
    (s) => s.copyWith(needs100: {for (final n in Need.values) n: 10000}),
  );

  void demoAppearance(Appearance a) =>
      _demoSet((s) => s.copyWith(appearance: a, owned: {...s.owned, ...a.ids}));

  /// Derecho simulado de la demostración; nunca toca el documento real.
  void demoEntitlement(EntitlementState state) {
    if (!demo) return;
    purchases.setDemo(
      Entitlement(
        state: state,
        source: EntitlementSource.simulated,
        updatedUtc: clock.nowUtcSeconds(),
      ),
    );
  }
}
