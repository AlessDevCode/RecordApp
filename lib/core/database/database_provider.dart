// lib/core/database/database_provider.dart
import 'package:recordapp/core/database/database_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
DatabaseHelper databaseHelper(Ref ref) {
  final DatabaseHelper helper = DatabaseHelper();
  ref.onDispose(helper.close);
  return helper;
}
