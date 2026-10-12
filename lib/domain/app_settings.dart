/// Parámetros que cambian por decisión de la empresa (GET /api/settings).
/// Si falta alguna clave, fromMap lanza error: así nunca se usa un valor inventado.
/// Archivo que establece politicas de la empresa como 10s de gracia emtros de lleuge aut,
/// por medio de la api
library;

class AppSettings {
  const AppSettings({
    required this.arrivalRadiusM,
    required this.arrivalDwellS,
    required this.waitBaseMin,
    required this.waitPerKmMin,
    required this.minClientContacts,
    required this.minOfficeCalls,
    required this.undoSeconds,
    required this.creditAuthorizationWaitMin,
    required this.photoTargetKb,
    required this.videoMaxS,
  });

  final int arrivalRadiusM;
  final int arrivalDwellS;
  final int waitBaseMin;
  final int waitPerKmMin;
  final int minClientContacts;
  final int minOfficeCalls;
  final int undoSeconds;
  final int creditAuthorizationWaitMin;
  final int photoTargetKb;
  final int videoMaxS;

  factory AppSettings.fromMap(Map<String, dynamic> j) => AppSettings(
    arrivalRadiusM: (j['arrival_radius_m'] as num).toInt(), 
    arrivalDwellS: (j['arrival_dwell_s']as num).toInt(), 
    waitBaseMin: (j['wait_base_min']as num).toInt(), 
    waitPerKmMin: (j['wait_per_km_min']as num).toInt(), 
    minClientContacts: (j['min_client_contacts']as num).toInt(), 
    minOfficeCalls: (j['min_office_calls']as num).toInt(), 
    undoSeconds: (j['undo_seconds']as num).toInt(), 
    creditAuthorizationWaitMin: (j['credit_authorization_wait_min']as num).toInt(), 
    photoTargetKb: (j['photo_target_kb']as num).toInt(), 
    videoMaxS: (j['video_max_s'] as num).toInt()
  );
  
  Map<String, dynamic> toMap() => {
    'arrival_radius_m': arrivalRadiusM,
    'arrival_dwell_s': arrivalDwellS,
    'wait_base_min': waitBaseMin,
    'wait_per_km_min': waitPerKmMin,
    'min_client_contacts': minClientContacts,
    'min_office_calls': minOfficeCalls,
    'undo_seconds': undoSeconds,
    'credit_authorization_wait_min': creditAuthorizationWaitMin,
    'photo_target_kb': photoTargetKb,
    'video_max_s': videoMaxS,
  };

}