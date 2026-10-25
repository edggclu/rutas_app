import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/application/review_actions.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/payload.dart';
import 'package:telyser_app/domain/models/review_models.dart';
import 'package:telyser_app/domain/review_rules.dart';

/// Repositorio falso: solo anota qué se le pidió.
class _FakeRepo implements ReviewRepository {
  final calls = <String>[];

  @override
  Future<List<ReviewJob>> fetchPending() async => [];

  @override
  Future<void> validate(int jobId) async {
    calls.add('validate:$jobId');
  }

  @override
  Future<void> returnJob(int jobId, String note) async {
    calls.add('return:$jobId:$note');
  }

  @override
  Future<void> submitVerdict(int jobId, WarrantyCause cause) async {
    calls.add('verdict:$jobId:${cause.code}');
  }
}

void main() {
  late List<ReviewJob> jobs;
  late _FakeRepo repo;
  late ReviewActions actions;
  late int changes; // cuántas veces avisó que algo cambió

  setUp(() {
    final raw = json.decode(File('assets/mock/review.json').readAsStringSync()) as Map<String, dynamic>;
    jobs = [for (final m in readMaps(raw, 'jobs')) ReviewJob.fromJson(m)];
    repo = _FakeRepo();
    changes = 0;
    actions = ReviewActions(repo, onChanged: () => changes++);
  });

  test('review.json trae tres trabajos con sus datos', () {
    expect(jobs.length, 3);
    expect(jobs.first.folio, 'TEL-2610-011');
    expect(jobs.first.photos.length, 3);
    expect(jobs.first.plan!.materials.length, 3);
    expect(jobs[1].failurePhotos.length, 2); // la falla y la etiqueta
  });

  test('solo la garantía con causa desconocida pide dictamen', () {
    expect(jobs[0].needsVerdict, isFalse);
    expect(jobs[1].needsVerdict, isTrue);
    expect(jobs[2].needsVerdict, isFalse);
  });

  test('dictaminar quita la pendiente', () {
    final done = jobs[1].withVerdict(WarrantyCause.humiditySalt);
    expect(done.needsVerdict, isFalse);
    expect(done.warranty!.verdict, WarrantyCause.humiditySalt);
  });

  test('canValidate y canReturnJob', () {
    expect(canValidate(jobs[0]), isTrue);
    expect(canValidate(jobs[1]), isFalse); // falta el dictamen
    expect(canReturnJob(''), isFalse);
    expect(canReturnJob('   '), isFalse);
    expect(canReturnJob('Falta la foto'), isTrue);
  });

  test('validar un trabajo correcto lo manda al repositorio y avisa', () async {
    await actions.validate(jobs[0]);
    expect(repo.calls, ['validate:11']);
    expect(changes, 1);
  });

  test('no se valida una garantía sin dictaminar', () async {
    await expectLater(actions.validate(jobs[1]), throwsStateError);
    expect(repo.calls, isEmpty); // ni siquiera llegó al repositorio
    expect(changes, 0);
  });

  test('regresar exige nota y la manda sin espacios sobrantes', () async {
    await expectLater(actions.returnJob(jobs[0], '  '), throwsArgumentError);
    await actions.returnJob(jobs[0], ' Falta la foto del grabador ');
    expect(repo.calls, ['return:11:Falta la foto del grabador']);
    expect(changes, 1);
  });

  test('el dictamen se manda con su código', () async {
    await actions.submitVerdict(jobs[1], WarrantyCause.powerSurge);
    expect(repo.calls, ['verdict:17:power_surge']);
  });
}