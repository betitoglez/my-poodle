import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../ads/ads.dart';
import '../data/save_codec.dart';
import '../data/save_store.dart';
import '../data/storage_backend.dart';
import '../domain/balance.dart';
import '../domain/needs_clock.dart';
import '../game/pet/appearance_catalog.dart';
import '../game/pet/pet_painter.dart';
import '../game/pet/pet_sprites.dart';
import '../platform/platform_backend.dart';
import '../ui/screens/adoption_screen.dart';
import '../ui/screens/loading_screen.dart';
import '../ui/screens/main_shell.dart';
import '../ui/navigation.dart';
import '../ui/theme.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'feedback.dart';

/// Dependencias construidas una vez en el arranque.
class AppServices {
  AppServices({required this.controller, required this.painter});
  final AppController controller;
  final PetPainter painter;

  static Future<AppServices> create({
    StorageBackend? backend,
    Clock? clock,
    bool loadSprites = true,
  }) async {
    final balance = Balance.fromJson(
      jsonDecode(await rootBundle.loadString('assets/data/balance-v1.json'))
          as Map<String, dynamic>,
    );
    final looks = AppearanceCatalog.fromJson(
      jsonDecode(await rootBundle.loadString('assets/data/appearance-v1.json'))
          as Map<String, dynamic>,
    );
    final store = SaveStore(
      backend ?? await createPlatformBackend(),
      SaveCodec(balance),
    );
    final controller = AppController(
      balance: balance,
      looks: looks,
      store: store,
      clock: clock ?? const SystemClock(),
    );
    final painter = PetPainter(looks);
    // El atlas ilustrado se carga sin bloquear el arranque; hasta entonces
    // (o si falla) se dibuja el caniche vectorial.
    if (loadSprites) {
      PetSprites.load(rootBundle)
          .then<void>((s) => painter.sprites = s)
          .catchError((Object e) {
            debugPrint('Atlas del caniche no disponible: $e');
          });
    }
    return AppServices(controller: controller, painter: painter);
  }
}

/// Acceso al pintor compartido del caniche (una instancia por app).
class PetPainterScope extends InheritedWidget {
  const PetPainterScope({
    super.key,
    required this.painter,
    required super.child,
  });
  final PetPainter painter;
  static PetPainter of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PetPainterScope>()!.painter;
  @override
  bool updateShouldNotify(PetPainterScope oldWidget) => false;
}

class MyPoodleApp extends StatefulWidget {
  const MyPoodleApp({
    super.key,
    this.backend,
    this.clock,
    this.loadSprites = true,
  });
  final StorageBackend? backend;
  final Clock? clock;
  final bool loadSprites;

  @override
  State<MyPoodleApp> createState() => _MyPoodleAppState();
}

class _MyPoodleAppState extends State<MyPoodleApp> {
  AppServices? _services;
  Object? _error;
  final _feedback = FeedbackService();
  final _ads = AdsController();
  final _shell = ShellController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final s =
          _services ??
          await AppServices.create(
            backend: widget.backend,
            clock: widget.clock,
            loadSprites: widget.loadSprites,
          );
      _feedback.prefs = () => s.controller.prefs;
      setState(() => _services = s);
      await s.controller.boot();
    } catch (e, st) {
      debugPrint('Arranque fallido: $e\n$st');
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _services?.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _services;
    Widget home;
    if (s == null) {
      home = LoadingScreen(
        error: _error == null ? null : 'No se pudieron cargar los recursos.',
        onRetry: _start,
      );
    } else {
      home = const _BootGate();
    }
    return MaterialApp(
      title: 'My Poodle',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('es'),
      builder: (context, child) {
        // Las escenas y diálogos comparten el mismo AppScope.
        if (s == null) return child!;
        return AppScope(
          controller: s.controller,
          feedback: _feedback,
          ads: _ads,
          child: ShellScope(
            controller: _shell,
            child: PetPainterScope(painter: s.painter, child: child!),
          ),
        );
      },
      home: home,
    );
  }
}

/// Decide Adopción o Casa después de leer la partida local.
class _BootGate extends StatelessWidget {
  const _BootGate();

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return switch (c.status) {
      BootStatus.loading => const LoadingScreen(),
      BootStatus.adoption => const AdoptionScreen(),
      BootStatus.ready => const MainShell(),
      BootStatus.ioError => LoadingScreen(
        error:
            'No se ha podido leer la partida guardada. No se ha borrado nada.',
        onRetry: c.boot,
      ),
      BootStatus.corrupted => LoadingScreen(
        error: 'La partida guardada está dañada. Se conserva sin cambios; una persona adulta puede reiniciarla.',
        onRetry: c.boot,
        allowAdultReset: true,
      ),
      BootStatus.futureSchema => LoadingScreen(
        error: 'Esta partida es de una versión más nueva del juego. Actualiza la app para seguir jugando.',
        onRetry: c.boot,
      ),
    };
  }
}
