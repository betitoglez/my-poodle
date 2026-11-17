import 'dart:convert';
import 'dart:io';

import 'package:my_poodle/domain/balance.dart';

/// Carga la copia empaquetada del balance (equivalente a docs/datos).
Balance loadBalance() => Balance.fromJson(
  jsonDecode(File('assets/data/balance-v1.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// 2026-11-16T12:00:00Z
const int t0 = 1794830400;
