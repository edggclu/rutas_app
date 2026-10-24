import 'package:flutter_riverpod/flutter_riverpod.dart'; // FutureProvider

import '../domain/models/my_job_models.dart'; // MyJob y sortMyJobs
import 'infra_providers.dart'; // myJobsRepositoryProvider
import 'session_provider.dart'; // sessionProvider

/// Los trabajos terminados del técnico, ya ordenados. Se vuelve a pedir al cambiar de sesión
/// o al jalar para actualizar.
final myJobsProvider = FutureProvider<List<MyJob>>((ref) async {
  ref.watch(sessionProvider);
  final jobs = await ref.watch(myJobsRepositoryProvider).fetch();
  return sortMyJobs(jobs);
});
