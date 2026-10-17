import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/settings_store.dart';
import 'package:telyser_app/domain/app_settings.dart';

void main(){
  late AppDatabase db;
  late SettingsStore store;
  late AppSettings settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SettingsStore(db);
    final raw = File('assets/mock/settings.json').readAsStringSync();
    settings = AppSettings.fromMap(json.decode(raw) as Map<String, dynamic>);
  });

  tearDown(() => db.close());

  test('settings.json trae todas las claves del contrato', (){
    expect (settings.undoSeconds, 10);
    expect(settings.arrivalRadiusM, 150);
    expect(settings.videoMaxS, 60);
    expect(settings.officePhone, '3220000000'); // el teléfono de la oficina llega del JSON
  });

  test('sin nada guardado, load devuelve null', () async {
    expect(await store.load(), isNull);
  });

  test('lo guardado se lee igual (sin señal)', () async {
    await store.save((settings));
    final back = await store.load();
    expect(back!.toMap(), settings.toMap());
  });

  test('guardar de nuevo reemplaza el valor', ()  async{
    await store.save(settings);
    final changed = AppSettings.fromMap({...settings.toMap(), 'undo_seconds': 15});
    await store.save(changed);
    expect((await store.load())!.undoSeconds, 15);
  });


}