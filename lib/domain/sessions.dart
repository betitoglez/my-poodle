/// Registro en memoria de sesiones de actividad. Pasos, colisiones y
/// puntuación provisional nunca van a disco; solo la finalización guarda.
class SessionRegistry {
  SessionRegistry({String Function()? idFactory})
    : _idFactory = idFactory ?? _defaultId;

  final String Function() _idFactory;
  final Map<String, String> _open = {}; // sessionId -> activityId
  final Map<String, Object> _receipts = {}; // sessionId -> recibo
  final Set<String> _cancelled = {};

  static int _seq = 0;
  static String _defaultId() =>
      's${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  String begin(String activityId) {
    final id = _idFactory();
    _open[id] = activityId;
    return id;
  }

  bool isOpen(String sessionId) => _open.containsKey(sessionId);
  String? activityOf(String sessionId) => _open[sessionId];

  void cancel(String sessionId) {
    if (_open.remove(sessionId) != null) _cancelled.add(sessionId);
  }

  /// Recibo previo si la sesión ya terminó (callback duplicado).
  T? receiptOf<T>(String sessionId) => _receipts[sessionId] as T?;

  bool wasCancelled(String sessionId) => _cancelled.contains(sessionId);

  void complete(String sessionId, Object receipt) {
    _open.remove(sessionId);
    _receipts[sessionId] = receipt;
  }
}
