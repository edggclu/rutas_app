import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/location_access.dart';
import '../../../providers/infra_providers.dart';
import '../../../providers/location_providers.dart';

/// Aviso en Mi día cuando la app no puede leer la ubicación. Explica para qué se usa antes de
/// pedir el permiso. "Llegué" funciona igual sin ubicación; solo se guarda sin coordenadas.
/// Desaparece solo cuando el permiso queda dado y el GPS prendido.
class LocationBanner extends ConsumerStatefulWidget {
  const LocationBanner({super.key});

  @override
  ConsumerState<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends ConsumerState<LocationBanner> with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // para enterarse cuando regresa de los ajustes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(locationAccessProvider); // revisa de nuevo
  }

  Future<void> _act(LocationAccess access) async {
    final service = ref.read(locationServiceProvider);
    setState(() => _busy = true);
    try {
      if (access == LocationAccess.denied) {
        await service.request(); // ventana de Android
      } else {
        await service.openSettings(); // negado para siempre o GPS apagado: se cambia a mano
      }
    } finally {
      ref.invalidate(locationAccessProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  ({String title, String body, String button}) _texts(LocationAccess access) => switch (access) {
        LocationAccess.deniedForever => (
            title: 'La ubicación está bloqueada',
            body: 'Para guardar dónde llegaste, actívala en los ajustes de la app.',
            button: 'Abrir ajustes',
          ),
        LocationAccess.serviceOff => (
            title: 'El GPS está apagado',
            body: 'Préndelo para guardar dónde llegaste.',
            button: 'Abrir ajustes',
          ),
        _ => (
            title: 'Permite la ubicación',
            body: 'La usamos solo al marcar "Llegué", para guardar que estás en el sitio. '
                'Puedes trabajar sin ella.',
            button: 'Permitir',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(locationAccessProvider).value;
    if (access == null || access.isGranted) return const SizedBox.shrink(); // cargando o todo en orden
    final t = _texts(access);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.infoSuave, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.info, fontSize: 13)),
                const SizedBox(height: 2),
                Text(t.body, style: const TextStyle(color: AppColors.gris900, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _busy ? null : () => _act(access),
            child: Text(t.button),
          ),
        ],
      ),
    );
  }
}
