import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../domain/models/review_models.dart';

/// Tira horizontal de fotos. Al tocar una se abre ampliada, con zoom.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos});

  final List<ReviewPhoto> photos;

  void _open(BuildContext context, ReviewPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 360,
              child: InteractiveViewer(child: AppImage(src: photo.src, fit: BoxFit.contain)), // pellizcar para acercar
            ),
            if (photo.caption != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(photo.caption!)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Text('Sin fotos.', style: TextStyle(color: AppColors.gris600));
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _open(context, photos[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 120, height: 120, child: AppImage(src: photos[i].src)),
          ),
        ),
      ),
    );
  }
}