import 'dart:convert'; // json.decode para leer el JSON de prueba
import 'dart:io'; // File para leer el archivo de prueba

import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/domain/models/my_job_models.dart'; // lo que se prueba
import 'package:telyser_app/domain/models/payload.dart'; // readMaps

void main() {
  late List<MyJob> jobs;

  setUp(() {
    final raw = json.decode(File('assets/mock/my_jobs.json').readAsStringSync()) as Map<String, dynamic>;
    jobs = [for (final m in readMaps(raw, 'jobs')) MyJob.fromJson(m)];
  });

  test('my_jobs.json trae un trabajo en cada estado', () {
    expect(jobs.map((j) => j.status).toSet(), MyJobStatus.values.toSet());
  });

  test('solo el regresado trae la nota del ingeniero', () {
    for (final j in jobs) {
      expect(j.engineerNote != null, j.status == MyJobStatus.returned, reason: j.folio);
    }
  });

  test('un estado desconocido se lee como por validar', () {
    expect(MyJobStatus.parse('algo_nuevo'), MyJobStatus.toValidate);
    expect(MyJobStatus.parse(null), MyJobStatus.toValidate);
  });

  test('el orden pone primero regresados, luego por validar y al final validados', () {
    final sorted = sortMyJobs(jobs);
    expect(sorted.map((j) => j.status), [
      MyJobStatus.returned,
      MyJobStatus.toValidate,
      MyJobStatus.validated,
    ]);
  });
}
