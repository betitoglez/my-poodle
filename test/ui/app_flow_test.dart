import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_root.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/app/feedback.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/store/store_provider.dart';
import 'package:my_poodle/ui/parental_gate.dart';
import 'package:my_poodle/ui/widgets/common.dart';

import '../support.dart';

/// Recorridos de aceptación sobre la app real (dominio, guardado en memoria,
/// escenas Flame y widgets). Avanza el tiempo explícitamente: nunca
/// pumpAndSettle sobre un bucle Flame infinito.
Future<void> frames(WidgetTester t, {double seconds = 1, int fps = 30}) async {
  final n = (seconds * fps).round();
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: (1000 / fps).round()));
  }
}

Future<void> idle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await frames(t, seconds: 0.6);
}

Future<void> boot(
  WidgetTester t,
  MemoryBackend backend, {
  Size size = const Size(390, 844),
  int? now,
  Clock? clock,
  StoreProvider? store,
  EffectPlayback? effectPlayback,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MyPoodleApp(
      backend: backend,
      clock: clock ?? FakeClock(now ?? t0),
      storeProvider: store ?? SimulatedStore(delay: Duration.zero),
      effectPlayback: effectPlayback,
    ),
  );
  // Espera real a la carga de recursos y partida (E/S asíncrona).
  for (var i = 0; i < 40; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 16));
    if (find.textContaining('Cargando').evaluate().isEmpty) break;
  }
  await idle(t);
  if (find.textContaining('Cargando').evaluate().isNotEmpty) {
    debugPrint(
      'SIGUE CARGANDO: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}',
    );
  }
}

/// Reinicia la app sobre el mismo almacenamiento (cerrar y abrir).
Future<void> reopen(WidgetTester t, MemoryBackend backend, {int? now}) async {
  await t.pumpWidget(const SizedBox());
  await t.pump();
  await boot(t, backend, now: now);
}

/// Desplaza la lista visible hasta construir y mostrar [finder].
Future<void> scrollTo(WidgetTester t, Finder finder) async {
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  final vertical = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axis == Axis.vertical,
  );
  await t.scrollUntilVisible(finder, 200, scrollable: vertical.last);
  await t.pump();
}

Future<void> tapText(WidgetTester t, String text) async {
  var f = find.text(text).hitTestable();
  if (f.evaluate().isEmpty && find.text(text).evaluate().isNotEmpty) {
    // Puede estar en una fila desplazable (p. ej. submenús del armario).
    await t.ensureVisible(find.text(text).first);
    await t.pump();
    f = find.text(text).hitTestable();
  }
  expect(f, findsWidgets, reason: 'No se encuentra «$text»');
  await t.tap(f.first);
  await idle(t);
}

Future<void> tapIcon(WidgetTester t, IconData icon) async {
  await t.tap(find.byIcon(icon).hitTestable().first);
  await idle(t);
}

PetState saved(MemoryBackend b) =>
    SaveCodec(loadBalance()).decode(b.files[SaveStore.primary]!);

/// Supera la puerta adulta (número fijo 47 en las pruebas).
Future<void> passGate(WidgetTester t, {String answer = '47'}) async {
  await t.enterText(find.byKey(const Key('parental-gate-field')), answer);
  await t.pump();
  await t.tap(find.text('Continuar').hitTestable().last);
  await idle(t);
}

/// Abre la Zona adulta desde Ajustes.
Future<void> openAdultZone(WidgetTester t) async {
  await tapIcon(t, Icons.settings_rounded);
  final gate = find.text('Acceso para personas adultas');
  await scrollTo(t, gate);
  await tapText(t, 'Acceso para personas adultas');
  await passGate(t);
}

/// Tienda simulada en la que la versión completa ya es de la cuenta.
SimulatedStore fullStore() => SimulatedStore(owned: true, delay: Duration.zero);

Future<void> adopt(WidgetTester t, String name) async {
  await t.enterText(find.byType(TextField), name);
  await t.pump();
  await tapText(t, 'Adoptar');
}

void main() {
  // La caché de rootBundle guarda futuros de la zona de la prueba anterior.
  setUp(() {
    rootBundle.clear();
    ParentalGate.nextNumber = () => 47;
  });
  tearDown(ParentalGate.reset);

  testWidgets('1 y 10 · adoptar con nombre y conservarlo al reabrir', (
    t,
  ) async {
    final backend = MemoryBackend();
    await boot(t, backend);
    expect(find.text('Tu caniche toy'), findsOneWidget);
    await adopt(t, '  María José ');
    expect(find.text('María José'), findsWidgets);
    expect(saved(backend).coins, 0);
    await reopen(t, backend);
    expect(find.text('Tu caniche toy'), findsNothing);
    expect(find.text('María José'), findsWidgets);
  });

  testWidgets(
    'adopción rechaza nombre vacío y de 17 caracteres sin crear partida',
    (t) async {
      final backend = MemoryBackend();
      await boot(t, backend);
      await tapText(t, 'Adoptar');
      expect(find.text('Escribe un nombre para tu caniche.'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'abcdefghijklmnopq');
      await t.pump();
      await tapText(t, 'Adoptar');
      expect(
        find.text('Elige un nombre de 1 a 16 caracteres.'),
        findsOneWidget,
      );
      expect(backend.files, isEmpty);
    },
  );

  testWidgets(
    '2 · comer: tres bocados, +20 una sola vez; salir a medias no aplica',
    (t) async {
      final backend = MemoryBackend();
      await boot(t, backend);
      await adopt(t, 'Miel');
      await tapText(t, 'Cuidados');
      await tapText(t, 'Comer');
      await tapText(t, 'Pienso diario · Gratis');
      // Salir tras dos bocados: no aplica la mejora.
      await tapText(t, 'Dar un bocado');
      await frames(t, seconds: 1.5);
      await tapText(t, 'Dar un bocado');
      await frames(t, seconds: 1.5);
      await tapIcon(t, Icons.close_rounded);
      expect(find.text('¿Salir de comer?'), findsOneWidget);
      await tapText(t, 'Salir');
      expect(saved(backend).needPoints(Need.satiety), 65);
      // Completar: 65 → 85.
      await tapText(t, 'Comer');
      await tapText(t, 'Pienso diario · Gratis');
      for (var i = 0; i < 3; i++) {
        await tapText(t, 'Dar un bocado');
        // Toque durante la masticación: no cuenta.
        if (i == 0) {
          await t.tap(find.text('Masticando…').first);
          await t.pump();
        }
        await frames(t, seconds: 1.5);
      }
      await idle(t);
      expect(find.text('65 → 85'), findsOneWidget);
      expect(saved(backend).needPoints(Need.satiety), 85);
      expect(saved(backend).revision, 2);
      expect(saved(backend).coins, 0);
    },
  );

  testWidgets('el medidor de hidratación abre el cuenco y guarda tres sorbos', (
    t,
  ) async {
    final balance = loadBalance();
    final state = PetState.adopt(
      validName: 'Miel',
      nowUtc: t0,
      balance: balance,
    ).copyWith(needs100: {...balance.initial100, Need.hydration: 2000});
    final backend = MemoryBackend();
    backend.files[SaveStore.primary] = SaveCodec(balance).encode(state);
    await boot(t, backend);
    await tapText(t, 'Hidratación');
    await tapText(t, 'Agua · Gratis');
    await tapText(t, 'Llenar el cuenco');
    await frames(t, seconds: 1.2);
    expect(saved(backend).needPoints(Need.hydration), 20);
    for (var i = 0; i < 3; i++) {
      await tapText(t, 'Dar un sorbo');
      await frames(t, seconds: 1.5);
    }
    await idle(t);
    expect(find.text('20 → 80'), findsOneWidget);
    expect(saved(backend).needPoints(Need.hydration), 80);
  });

  testWidgets('la bebida de pago se confirma y se cobra al tercer sorbo', (
    t,
  ) async {
    final balance = loadBalance();
    final state =
        PetState.adopt(
          validName: 'Miel',
          nowUtc: t0,
          balance: balance,
        ).copyWith(
          coins: 15,
          needs100: {
            ...balance.initial100,
            Need.hydration: 1000,
            Need.energy: 3000,
            Need.mood: 5000,
          },
        );
    final backend = MemoryBackend();
    backend.files[SaveStore.primary] = SaveCodec(balance).encode(state);
    await boot(t, backend);
    await tapText(t, 'Hidratación');
    await tapText(t, 'Agua con vitaminas');
    await tapText(t, 'Llenar el cuenco');
    expect(find.text('Confirmar la bebida'), findsOneWidget);
    await tapText(t, 'Cancelar');
    expect(saved(backend).coins, 15);
    await tapText(t, 'Llenar el cuenco');
    await tapText(t, 'Aceptar');
    await frames(t, seconds: 1.2);
    for (var i = 0; i < 2; i++) {
      await tapText(t, 'Dar un sorbo');
      await frames(t, seconds: 1.5);
    }
    expect(saved(backend).coins, 15);
    expect(saved(backend).needPoints(Need.hydration), 10);
    await tapText(t, 'Dar un sorbo');
    await frames(t, seconds: 1.5);
    await idle(t);
    final after = saved(backend);
    expect(after.coins, 0);
    expect(after.needPoints(Need.hydration), 100);
    expect(after.needPoints(Need.energy), 60);
    expect(after.needPoints(Need.mood), 60);
  });

  testWidgets('una ración de pago se confirma y solo se cobra al terminar', (
    t,
  ) async {
    final balance = loadBalance();
    final seed = PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance)
        .copyWith(
          coins: 30,
          needs100: {...balance.initial100, Need.satiety: 2000},
        );
    final backend = MemoryBackend()
      ..files[SaveStore.primary] = SaveCodec(balance).encode(seed);
    await boot(t, backend);
    await tapText(t, 'Cuidados');
    await tapText(t, 'Comer');
    await tapText(t, 'Comida premium');
    expect(find.text('Confirmar la ración'), findsNothing);
    expect(find.text('Pienso diario · Gratis'), findsOneWidget);
    await tapText(t, 'Dar un bocado');
    expect(find.text('Confirmar la ración'), findsOneWidget);
    await tapText(t, 'Cancelar');
    expect(saved(backend).coins, 30);
    expect(saved(backend).needPoints(Need.satiety), 20);

    await tapText(t, 'Dar un bocado');
    await tapText(t, 'Aceptar');
    await frames(t, seconds: 1.5);
    await tapIcon(t, Icons.close_rounded);
    await tapText(t, 'Salir');
    expect(saved(backend).coins, 30);
    expect(saved(backend).needPoints(Need.satiety), 20);

    await tapText(t, 'Comer');
    await tapText(t, 'Comida premium');
    await tapText(t, 'Dar un bocado');
    await tapText(t, 'Aceptar');
    for (var bite = 2; bite <= 3; bite++) {
      await frames(t, seconds: 1.5);
      await tapText(t, 'Dar un bocado');
    }
    await frames(t, seconds: 1.5);
    expect(saved(backend).coins, 20);
    expect(saved(backend).needPoints(Need.satiety), 60);
  });

  testWidgets('Frisbee termina con un acierto al agotar los 20 segundos', (
    t,
  ) async {
    final backend = MemoryBackend();
    await boot(t, backend);
    await adopt(t, 'Miel');
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await idle(t);
    await tapText(t, 'Frisbee en el prado');
    await tapText(t, 'Jugar');
    await tapText(t, 'Lanzar al aro');
    await frames(t, seconds: 21);
    await idle(t);
    final score = find.text('1 de 5 capturas · ¡nuevo récord!');
    expect(score, findsOneWidget);
    final controller = AppScope.read(t.element(score));
    await t.runAsync(() => controller.markHintSeen('test.result'));
    await idle(t);
    expect(t.takeException(), isNull);
    expect(score, findsOneWidget);
    expect(saved(backend).coins, 6);
  });

  testWidgets(
    '3 a 7 · frisbee 18 monedas, pañuelo, quitar/poner, vista previa cancelada',
    (t) async {
      final backend = MemoryBackend();
      await boot(t, backend);
      await adopt(t, 'Miel');
      await tapText(t, 'Juegos');
      await t.ensureVisible(find.text('Frisbee en el prado'));
      await idle(t);
      await tapText(t, 'Frisbee en el prado');
      expect(
        find.text('Duración: 20 segundos · 5 lanzamientos.'),
        findsOneWidget,
      );
      await tapText(t, 'Jugar');
      for (var i = 0; i < 5; i++) {
        await tapText(t, 'Lanzar al aro');
        // Segundo toque en vuelo: no lanza otra vez.
        await t.tap(find.text('Lanzar al aro').first, warnIfMissed: false);
        await frames(t, seconds: 2.8);
      }
      await idle(t);
      expect(find.text('+18 monedas'), findsOneWidget);
      expect(saved(backend).coins, 18);
      await tapText(t, 'Casa');
      await tapText(t, 'Armario');
      await tapText(t, 'Accesorios');
      await tapText(t, 'Cuello');
      await tapText(t, 'Pañuelo coral');
      await tapText(t, 'Comprar y usar · 10');
      expect(find.text('Saldo restante'), findsOneWidget);
      await tapText(t, 'Confirmar');
      expect(saved(backend).coins, 8);
      expect(saved(backend).appearance.neck, 'neck.coral');
      await tapText(t, 'Quitar');
      expect(saved(backend).appearance.neck, 'neck.none');
      await tapText(t, 'Pañuelo coral');
      await tapText(t, 'Usar');
      expect(
        [saved(backend).coins, saved(backend).appearance.neck],
        [8, 'neck.coral'],
      );
      // Vista previa de plata (24) sin saldo: descartar conserva el aspecto.
      await tapText(t, 'Colores');
      await tapText(t, 'Gris plata');
      expect(find.text('Faltan 16 · Jugar'), findsOneWidget);
      await tapText(t, 'Casa');
      expect(find.text('¿Te quedas con este aspecto?'), findsOneWidget);
      await tapText(t, 'Descartar');
      expect(saved(backend).appearance.coat, 'coat.apricot');
      expect(saved(backend).coins, 8);
      expect(find.text('En casa'.toUpperCase()), findsOneWidget);
    },
  );

  testWidgets('8 y 9 · pausa congela el huerto; abandonar no concede premio', (
    t,
  ) async {
    final backend = MemoryBackend();
    await boot(t, backend, store: fullStore());
    await adopt(t, 'Coco');
    await tapText(t, 'Juegos');
    await t.tap(find.text('Jugar').hitTestable().first);
    await idle(t);
    await tapText(t, 'Jugar');
    await frames(t, seconds: 2);
    await tapIcon(t, Icons.pause_circle_rounded);
    expect(find.text('En pausa'), findsOneWidget);
    final before = find
        .textContaining(' s')
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .toList();
    await frames(t, seconds: 5);
    final after = find
        .textContaining(' s')
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .toList();
    expect(after, before);
    await tapText(t, 'Continuar');
    await frames(t, seconds: 1);
    await tapIcon(t, Icons.close_rounded);
    expect(find.text('Seguir jugando'), findsOneWidget);
    await tapText(t, 'Salir');
    expect(saved(backend).coins, 0);
    expect(saved(backend).revision, 2);
  });

  testWidgets('huerto completo concede 2 + 2 por fruta una sola vez', (
    t,
  ) async {
    final backend = MemoryBackend();
    await boot(t, backend, store: fullStore());
    await adopt(t, 'Coco');
    await tapText(t, 'Juegos');
    await t.tap(find.text('Jugar').hitTestable().first);
    await idle(t);
    expect(find.textContaining('hasta 24 frutas'), findsOneWidget);
    expect(find.textContaining('60 segundos'), findsOneWidget);
    expect(find.textContaining('2 monedas + 2 por fruta'), findsOneWidget);
    await tapText(t, 'Jugar');
    await frames(t, seconds: 61);
    await idle(t);
    final coins = saved(backend).coins;
    expect(coins, greaterThanOrEqualTo(2));
    expect(find.text('+$coins monedas'), findsOneWidget);
    expect(find.textContaining('de 24 frutas'), findsOneWidget);
  });

  testWidgets('12 · reinicio: cancelar conserva, confirmar vuelve a Adopción', (
    t,
  ) async {
    final backend = MemoryBackend();
    await boot(t, backend);
    await adopt(t, 'Nube');
    await openAdultZone(t);
    expect(find.text('Zona adulta'), findsOneWidget);
    final reset = find.text('Reiniciar partida…');
    await scrollTo(t, reset);
    await tapText(t, 'Reiniciar partida…');
    await tapText(t, 'Cancelar');
    expect(backend.files.containsKey(SaveStore.primary), isTrue);
    await tapText(t, 'Reiniciar partida…');
    await tapText(t, 'Borrar partida');
    expect(backend.files, isEmpty);
    expect(find.text('Tu caniche toy'), findsOneWidget);
  });

  testWidgets('demostración no altera la partida normal', (t) async {
    final backend = MemoryBackend();
    await boot(t, backend);
    await adopt(t, 'Nube');
    final rev = saved(backend).revision;
    await openAdultZone(t);
    final demo = find.text('Entrar en modo demostración');
    await scrollTo(t, demo);
    await tapText(t, 'Entrar en modo demostración');
    await scrollTo(t, find.text('Necesidades bajas'));
    await tapText(t, 'Necesidades bajas');
    await scrollTo(t, find.text('100 monedas'));
    await tapText(t, '100 monedas');
    expect(find.text('DEMO'), findsWidgets);
    final exit = find.text('Salir del modo demostración');
    await scrollTo(t, exit);
    await tapText(t, 'Salir del modo demostración');
    expect(saved(backend).revision, rev);
    expect(saved(backend).coins, 0);
    expect(find.text('Nube'), findsWidgets);
  });

  testWidgets('P06 · compra externa durante frisbee conserva escena y premio', (
    t,
  ) async {
    final backend = MemoryBackend();
    final store = SimulatedStore(delay: Duration.zero);
    await boot(t, backend, store: store);
    await adopt(t, 'Coco');
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await tapText(t, 'Frisbee en el prado');
    await tapText(t, 'Jugar');
    final before = saved(backend).coins;
    store.emit(
      const StoreEvent(
        StoreEventKind.purchased,
        eventId: 'outside-game',
        productId: 'mypoodle.full_version',
      ),
    );
    await idle(t);
    expect(find.text('Pide ayuda a un adulto'), findsNothing);
    expect(find.text('Desbloquear'), findsNothing);
    expect(find.byIcon(Icons.pause_circle_rounded), findsOneWidget);
    expect(saved(backend).coins, before);
    await tapIcon(t, Icons.close_rounded);
    await tapText(t, 'Salir');
    expect(saved(backend).coins, before);
  });

  for (final size in const [Size(320, 568), Size(430, 932)]) {
    testWidgets(
      'P06 · ${size.width.toInt()}×${size.height.toInt()} · candados, puerta adulta y compra simulada',
      (t) async {
        final backend = MemoryBackend();
        final store = SimulatedStore(delay: Duration.zero)..online = false;
        await boot(t, backend, store: store, size: size);
        await adopt(t, 'Lola');
        // Ninguna oferta al arrancar ni en Casa.
        expect(find.textContaining('Desbloquear'), findsNothing);
        expect(find.textContaining('Pide ayuda'), findsNothing);

        // Huerto con candado: abre «Pide ayuda a un adulto» y Volver regresa.
        await tapText(t, 'Juegos');
        expect(find.text('Versión completa'), findsOneWidget);
        await tapText(t, 'Ver');
        expect(
          find.text('Esto es de la versión completa. Pide ayuda a un adulto'),
          findsOneWidget,
        );
        await tapText(t, 'Volver');
        expect(find.text('A jugar'), findsOneWidget);

        // Jersey: se prueba gratis, pero el botón pide ayuda; nada cambia.
        await tapText(t, 'Armario');
        await tapText(t, 'Ropa');
        final lockedTile = find.text('Versión completa').hitTestable();
        final grid = find.byType(CustomScrollView);
        for (var i = 0; i < 10 && lockedTile.evaluate().isEmpty; i++) {
          await t.drag(grid, const Offset(0, -150));
          await idle(t);
        }
        await t.tap(lockedTile.first);
        await idle(t);
        final askButton = find.widgetWithText(AppButton, 'Versión completa');
        expect(askButton, findsOneWidget);
        await t.tap(askButton);
        await idle(t);
        expect(find.text('Soy un adulto'), findsOneWidget);

        // Puerta adulta: un fallo cambia de número; acertar abre la compra.
        await tapText(t, 'Soy un adulto');
        await passGate(t, answer: '12');
        expect(find.textContaining('No es correcto'), findsOneWidget);
        await passGate(t);
        expect(find.textContaining('Pago único. Sin anuncios'), findsOneWidget);

        // Sin red: no disponible; con red, el precio de la tienda.
        await scrollTo(t, find.text('Restaurar compras'));
        expect(
          find.text('No disponible ahora. Inténtalo con conexión'),
          findsOneWidget,
        );
        store.online = true;
        await tapText(t, 'Reintentar');
        expect(find.text('Desbloquear por 1,99 €'), findsOneWidget);

        store.next = SimulatedOutcome.cancel;
        await tapText(t, 'Desbloquear por 1,99 €');
        expect(find.textContaining('Compra cancelada'), findsOneWidget);
        store.next = SimulatedOutcome.error;
        await tapText(t, 'Desbloquear por 1,99 €');
        expect(
          find.textContaining('No se ha podido completar'),
          findsOneWidget,
        );
        store.next = SimulatedOutcome.pending;
        await tapText(t, 'Reintentar');
        expect(find.textContaining('Esperando la aprobación'), findsOneWidget);
        expect(saved(backend).coins, 0);
        store.approvePending();
        await idle(t);
        expect(
          find.text('¡Gracias! Ya tienes la versión completa'),
          findsOneWidget,
        );

        // Vuelve al armario con el jersey en prueba y ya sin candado.
        await tapText(t, 'Volver');
        expect(
          find.widgetWithText(AppButton, 'Versión completa'),
          findsNothing,
        );
        expect(find.textContaining('Faltan'), findsOneWidget);
        await tapText(t, 'Descartar');
        await tapText(t, 'Juegos');
        // El Huerto ya no lleva candado.
        expect(find.text('Ver'), findsNothing);
        expect(find.text('Versión completa'), findsNothing);
        expect(find.text('Jugar'), findsWidgets);
        expect(
          saved(backend).owned.any((id) => id.startsWith('outfit.sweater')),
          isFalse,
        );
      },
    );
  }

  for (final size in const [Size(320, 568), Size(430, 932), Size(834, 1194)]) {
    testWidgets(
      '11 · ${size.width.toInt()}×${size.height.toInt()} sin desbordes',
      (t) async {
        final backend = MemoryBackend();
        await boot(t, backend, size: size);
        // Teclado abierto: el botón Adoptar sigue accesible.
        t.view.viewInsets = FakeViewPadding(bottom: size.height * 0.4);
        await idle(t);
        expect(find.text('Adoptar').hitTestable(), findsOneWidget);
        t.view.resetViewInsets();
        await adopt(t, 'Bartolomé Miel');
        for (final tab in ['Cuidados', 'Juegos', 'Armario', 'Casa']) {
          await tapText(t, tab);
          expect(t.takeException(), isNull, reason: tab);
        }
        expect(find.text('Bartolomé Miel'), findsWidgets);
      },
    );
  }
}
