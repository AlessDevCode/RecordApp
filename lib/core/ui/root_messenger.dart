// lib/core/ui/root_messenger.dart
import 'package:flutter/material.dart';

/// Clave global para mostrar SnackBars desde fuera del árbol de pantallas
/// (por ejemplo, las alertas de misión del escáner de fondo).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
