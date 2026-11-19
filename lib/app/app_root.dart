import '../l10n/app_strings.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/entitlement_store.dart';
import '../data/save_codec.dart';
import '../data/save_store.dart';
import '../data/storage_backend.dart';
import '../domain/balance.dart';
import '../domain/needs_clock.dart';
import '../game/pet/appearance_catalog.dart';
import '../game/pet/pet_painter.dart';
import '../game/pet/pet_sprites.dart';
import '../platform/platform_backend.dart';
import '../store/default_store.dart';
import '../store/simulated_store.dart';
import '../store/store_controller.dart';
import '../store/store_provider.dart';
import '../ui/screens/adoption_screen.dart';
import '../ui/screens/loading_screen.dart';
import '../ui/screens/main_shell.dart';
import '../ui/navigation.dart';
import '../ui/music_route_observer.dart';
import '../ui/theme.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'feedback.dart';
import 'background_music.dart';

/// Dependencias construidas una vez en el arranque.
class AppServices {
  AppServices({required this.controller, required this.painter});
  final AppController controller;
  final PetPainter painter;

  static Future<AppServices> create({
    StorageBackend? backend,
    Clock? clock,
    StoreProvider? storeProvider,
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
    final storage = backend ?? await createPlatformBackend();
    final store = SaveStore(storage, SaveCodec(balance));
    final theClock = clock ?? const SystemClock();
    // Tienda nativa en Android/iOS; web y escritorio sin tienda.
    final provider =
        storeProvider ?? createDefaultStore(balance.fullVersionProductId);
    final purchases = StoreController(
      provider: provider,
      entitlements: EntitlementStore(
        storage,
        productId: balance.fullVersionProductId,
        acceptSimulated: !kReleaseMode && provider is SimulatedStore,
      ),
      clock: theClock,
      simulated: provider is SimulatedStore,
    );
    final controller = AppController(
      balance: balance,
      looks: looks,
      store: store,
      clock: theClock,
      purchases: purchases,
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
    this.storeProvider,
    this.loadSprites = true,
    this.backgroundMusic,
    this.effectPlayback,
  });
  final StorageBackend? backend;
  final Clock? clock;

  /// Tienda inyectable (pruebas); por defecto según el tipo de build.
  final StoreProvider? storeProvider;
  final bool loadSprites;
  final BackgroundMusic? backgroundMusic;
  final EffectPlayback? effectPlayback;

  @override
  State<MyPoodleApp> createState() => _MyPoodleAppState();
}

class _MyPoodleAppState extends State<MyPoodleApp> with WidgetsBindingObserver {
  AppServices? _services;
  Object? _error;
  late final FeedbackService _feedback;
  late final MusicRouteObserver _musicRoutes;
  final _shell = ShellController();

  @override
  void initState() {
    super.initState();
    _feedback = FeedbackService(
      music: widget.backgroundMusic,
      playback: widget.effectPlayback,
    );
    _musicRoutes = MusicRouteObserver(_feedback.music);
    _feedback.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _feedback.music.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _feedback.music.setForeground(state == AppLifecycleState.resumed);
    _feedback.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      _services?.controller.onResumed();
    }
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final s =
          _services ??
          await AppServices.create(
            backend: widget.backend,
            clock: widget.clock,
            storeProvider: widget.storeProvider,
            loadSprites: widget.loadSprites,
          );
      _feedback.prefs = () => s.controller.prefs;
      if (_services != s) s.controller.addListener(_feedback.sync);
      s.controller.removeListener(_syncMusic);
      s.controller.addListener(_syncMusic);
      // Suscrito a la tienda antes de decidir Adopción o Casa.
      try {
        await s.controller.purchases.start();
      } catch (e) {
        debugPrint('Tienda no disponible: $e');
      }
      setState(() => _services = s);
      await s.controller.boot();
    } catch (e, st) {
      debugPrint('Arranque fallido: $e\n$st');
      setState(() => _error = e);
    }
  }

  void _syncMusic() {
    final c = _services?.controller;
    _feedback.music.setEnabled(
      c != null &&
          (c.status == BootStatus.ready || c.status == BootStatus.adoption) &&
          c.prefs.music,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _services?.controller.removeListener(_syncMusic);
    _services?.controller.removeListener(_feedback.sync);
    _feedback.dispose();
    _feedback.music.dispose();
    _services?.controller.dispose();
    _services?.controller.purchases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _services?.controller;
    if (controller == null) return _buildApp(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
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
      navigatorObservers: [_feedback.routes, _musicRoutes],
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: s?.controller.prefs.language == null
          ? null
          : AppLanguage.fromTag(s!.controller.prefs.language).locale,
      supportedLocales: AppLanguage.locales,
      localeListResolutionCallback: AppLanguage.resolve,
      localizationsDelegates: const [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      onGenerateTitle: (context) => AppStrings.of(context).appName,
      builder: (context, child) {
        AppStrings.active = AppStrings.of(context);
        // Las escenas y diálogos comparten el mismo AppScope.
        if (s == null) return child!;
        return Listener(
          onPointerDown: (_) => _feedback.music.onUserInteraction(),
          child: AppScope(
            controller: s.controller,
            feedback: _feedback,
            child: ShellScope(
              controller: _shell,
              child: PetPainterScope(painter: s.painter, child: child!),
            ),
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
