import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget

import '../../core/theme/app_colors.dart'; // colores
import '../../core/time/time_utils.dart'; // formatRelativeDay
import '../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../domain/models/notification_models.dart'; // AppNotification
import '../../providers/notifications_providers.dart'; // notificationsProvider

/// Avisos: lo que el servidor le dice al usuario (cambios de ruta, trabajos regresados o
/// validados, planes nuevos). Tocar un aviso lo marca como leído.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNoticesProvider);
    final unreadIds = [
      for (final n in notices.value ?? const <AppNotification>[])
        if (!n.read) n.id,
    ];
    return Column(
      children: [
        AppHeader(
          title: 'Avisos',
          subtitle: unread == 0 ? 'Todo al día' : '$unread sin leer',
          trailing: unread == 0
              ? null
              : TextButton(
                  onPressed: () => ref.read(markNoticesReadProvider)(unreadIds),
                  child: const Text('Marcar todo', style: TextStyle(color: Colors.white)),
                ),
        ),
        Expanded(
          child: notices.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los avisos. Revisa tu conexión.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
                    onPressed: () => ref.invalidate(notificationsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? const Center(
                    child: Text('No tienes avisos.', style: TextStyle(color: AppColors.gris600)),
                  )
                : RefreshIndicator( // jalar hacia abajo para actualizar
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                      await ref.read(notificationsProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _NoticeCard(
                        notice: list[i],
                        onTap: list[i].read ? null : () => ref.read(markNoticesReadProvider)([list[i].id]),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Ícono y color según el tipo de aviso.
({IconData icon, Color color, Color soft}) _style(NoticeType t) => switch (t) {
      NoticeType.jobReturned => (icon: Icons.undo, color: AppColors.rojoOscuro, soft: AppColors.rojoSuave),
      NoticeType.jobValidated => (icon: Icons.check_circle_outline, color: AppColors.ok, soft: AppColors.okSuave),
      NoticeType.routeChanged => (icon: Icons.alt_route, color: AppColors.alerta, soft: AppColors.alertaSuave),
      NoticeType.planUpdated => (icon: Icons.edit_note, color: AppColors.info, soft: AppColors.infoSuave),
      NoticeType.other => (icon: Icons.notifications_none, color: AppColors.gris600, soft: AppColors.gris100),
    };

/// Un aviso. Los no leídos llevan el título en negritas y un punto rojo.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final AppNotification notice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = _style(notice.type);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: s.soft, borderRadius: BorderRadius.circular(10)),
              child: Icon(s.icon, color: s.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: TextStyle(fontSize: 15, fontWeight: notice.read ? FontWeight.w500 : FontWeight.w700),
                        ),
                      ),
                      if (!notice.read)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.rojo, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notice.body, style: const TextStyle(fontSize: 13, color: AppColors.gris900)),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeDay(notice.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.gris600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
