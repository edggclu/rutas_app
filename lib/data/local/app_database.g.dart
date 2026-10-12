// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingsKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsKvData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsKvData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingsKvData extends DataClass implements Insertable<SettingsKvData> {
  final String key;
  final String value;
  const SettingsKvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsKvData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsKvData copyWith({String? key, String? value}) => SettingsKvData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsKvData copyWithCompanion(SettingsKvCompanion data) {
    return SettingsKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsKvData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingsKvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsKvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedVisitsTable extends CachedVisits
    with TableInfo<$CachedVisitsTable, CachedVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderInRouteMeta =
      const VerificationMeta('orderInRoute');
  @override
  late final GeneratedColumn<int> orderInRoute = GeneratedColumn<int>(
      'order_in_route', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arrivedAtUtcMeta =
      const VerificationMeta('arrivedAtUtc');
  @override
  late final GeneratedColumn<DateTime> arrivedAtUtc = GeneratedColumn<DateTime>(
      'arrived_at_utc', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _arrivalLatMeta =
      const VerificationMeta('arrivalLat');
  @override
  late final GeneratedColumn<double> arrivalLat = GeneratedColumn<double>(
      'arrival_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _arrivalLngMeta =
      const VerificationMeta('arrivalLng');
  @override
  late final GeneratedColumn<double> arrivalLng = GeneratedColumn<double>(
      'arrival_lng', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        orderInRoute,
        status,
        result,
        json,
        arrivedAtUtc,
        arrivalLat,
        arrivalLng
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_visits';
  @override
  VerificationContext validateIntegrity(Insertable<CachedVisit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('order_in_route')) {
      context.handle(
          _orderInRouteMeta,
          orderInRoute.isAcceptableOrUnknown(
              data['order_in_route']!, _orderInRouteMeta));
    } else if (isInserting) {
      context.missing(_orderInRouteMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('arrived_at_utc')) {
      context.handle(
          _arrivedAtUtcMeta,
          arrivedAtUtc.isAcceptableOrUnknown(
              data['arrived_at_utc']!, _arrivedAtUtcMeta));
    }
    if (data.containsKey('arrival_lat')) {
      context.handle(
          _arrivalLatMeta,
          arrivalLat.isAcceptableOrUnknown(
              data['arrival_lat']!, _arrivalLatMeta));
    }
    if (data.containsKey('arrival_lng')) {
      context.handle(
          _arrivalLngMeta,
          arrivalLng.isAcceptableOrUnknown(
              data['arrival_lng']!, _arrivalLngMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVisit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      orderInRoute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_in_route'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result']),
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      arrivedAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}arrived_at_utc']),
      arrivalLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}arrival_lat']),
      arrivalLng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}arrival_lng']),
    );
  }

  @override
  $CachedVisitsTable createAlias(String alias) {
    return $CachedVisitsTable(attachedDatabase, alias);
  }
}

class CachedVisit extends DataClass implements Insertable<CachedVisit> {
  final int id;
  final String date;
  final int orderInRoute;
  final String status;
  final String? result;
  final String json;
  final DateTime? arrivedAtUtc;
  final double? arrivalLat;
  final double? arrivalLng;
  const CachedVisit(
      {required this.id,
      required this.date,
      required this.orderInRoute,
      required this.status,
      this.result,
      required this.json,
      this.arrivedAtUtc,
      this.arrivalLat,
      this.arrivalLng});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['order_in_route'] = Variable<int>(orderInRoute);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(result);
    }
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || arrivedAtUtc != null) {
      map['arrived_at_utc'] = Variable<DateTime>(arrivedAtUtc);
    }
    if (!nullToAbsent || arrivalLat != null) {
      map['arrival_lat'] = Variable<double>(arrivalLat);
    }
    if (!nullToAbsent || arrivalLng != null) {
      map['arrival_lng'] = Variable<double>(arrivalLng);
    }
    return map;
  }

  CachedVisitsCompanion toCompanion(bool nullToAbsent) {
    return CachedVisitsCompanion(
      id: Value(id),
      date: Value(date),
      orderInRoute: Value(orderInRoute),
      status: Value(status),
      result:
          result == null && nullToAbsent ? const Value.absent() : Value(result),
      json: Value(json),
      arrivedAtUtc: arrivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivedAtUtc),
      arrivalLat: arrivalLat == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalLat),
      arrivalLng: arrivalLng == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalLng),
    );
  }

  factory CachedVisit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVisit(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      orderInRoute: serializer.fromJson<int>(json['orderInRoute']),
      status: serializer.fromJson<String>(json['status']),
      result: serializer.fromJson<String?>(json['result']),
      json: serializer.fromJson<String>(json['json']),
      arrivedAtUtc: serializer.fromJson<DateTime?>(json['arrivedAtUtc']),
      arrivalLat: serializer.fromJson<double?>(json['arrivalLat']),
      arrivalLng: serializer.fromJson<double?>(json['arrivalLng']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'orderInRoute': serializer.toJson<int>(orderInRoute),
      'status': serializer.toJson<String>(status),
      'result': serializer.toJson<String?>(result),
      'json': serializer.toJson<String>(json),
      'arrivedAtUtc': serializer.toJson<DateTime?>(arrivedAtUtc),
      'arrivalLat': serializer.toJson<double?>(arrivalLat),
      'arrivalLng': serializer.toJson<double?>(arrivalLng),
    };
  }

  CachedVisit copyWith(
          {int? id,
          String? date,
          int? orderInRoute,
          String? status,
          Value<String?> result = const Value.absent(),
          String? json,
          Value<DateTime?> arrivedAtUtc = const Value.absent(),
          Value<double?> arrivalLat = const Value.absent(),
          Value<double?> arrivalLng = const Value.absent()}) =>
      CachedVisit(
        id: id ?? this.id,
        date: date ?? this.date,
        orderInRoute: orderInRoute ?? this.orderInRoute,
        status: status ?? this.status,
        result: result.present ? result.value : this.result,
        json: json ?? this.json,
        arrivedAtUtc:
            arrivedAtUtc.present ? arrivedAtUtc.value : this.arrivedAtUtc,
        arrivalLat: arrivalLat.present ? arrivalLat.value : this.arrivalLat,
        arrivalLng: arrivalLng.present ? arrivalLng.value : this.arrivalLng,
      );
  CachedVisit copyWithCompanion(CachedVisitsCompanion data) {
    return CachedVisit(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      orderInRoute: data.orderInRoute.present
          ? data.orderInRoute.value
          : this.orderInRoute,
      status: data.status.present ? data.status.value : this.status,
      result: data.result.present ? data.result.value : this.result,
      json: data.json.present ? data.json.value : this.json,
      arrivedAtUtc: data.arrivedAtUtc.present
          ? data.arrivedAtUtc.value
          : this.arrivedAtUtc,
      arrivalLat:
          data.arrivalLat.present ? data.arrivalLat.value : this.arrivalLat,
      arrivalLng:
          data.arrivalLng.present ? data.arrivalLng.value : this.arrivalLng,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVisit(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('orderInRoute: $orderInRoute, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('json: $json, ')
          ..write('arrivedAtUtc: $arrivedAtUtc, ')
          ..write('arrivalLat: $arrivalLat, ')
          ..write('arrivalLng: $arrivalLng')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, orderInRoute, status, result, json,
      arrivedAtUtc, arrivalLat, arrivalLng);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVisit &&
          other.id == this.id &&
          other.date == this.date &&
          other.orderInRoute == this.orderInRoute &&
          other.status == this.status &&
          other.result == this.result &&
          other.json == this.json &&
          other.arrivedAtUtc == this.arrivedAtUtc &&
          other.arrivalLat == this.arrivalLat &&
          other.arrivalLng == this.arrivalLng);
}

class CachedVisitsCompanion extends UpdateCompanion<CachedVisit> {
  final Value<int> id;
  final Value<String> date;
  final Value<int> orderInRoute;
  final Value<String> status;
  final Value<String?> result;
  final Value<String> json;
  final Value<DateTime?> arrivedAtUtc;
  final Value<double?> arrivalLat;
  final Value<double?> arrivalLng;
  const CachedVisitsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.orderInRoute = const Value.absent(),
    this.status = const Value.absent(),
    this.result = const Value.absent(),
    this.json = const Value.absent(),
    this.arrivedAtUtc = const Value.absent(),
    this.arrivalLat = const Value.absent(),
    this.arrivalLng = const Value.absent(),
  });
  CachedVisitsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required int orderInRoute,
    required String status,
    this.result = const Value.absent(),
    required String json,
    this.arrivedAtUtc = const Value.absent(),
    this.arrivalLat = const Value.absent(),
    this.arrivalLng = const Value.absent(),
  })  : date = Value(date),
        orderInRoute = Value(orderInRoute),
        status = Value(status),
        json = Value(json);
  static Insertable<CachedVisit> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? orderInRoute,
    Expression<String>? status,
    Expression<String>? result,
    Expression<String>? json,
    Expression<DateTime>? arrivedAtUtc,
    Expression<double>? arrivalLat,
    Expression<double>? arrivalLng,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (orderInRoute != null) 'order_in_route': orderInRoute,
      if (status != null) 'status': status,
      if (result != null) 'result': result,
      if (json != null) 'json': json,
      if (arrivedAtUtc != null) 'arrived_at_utc': arrivedAtUtc,
      if (arrivalLat != null) 'arrival_lat': arrivalLat,
      if (arrivalLng != null) 'arrival_lng': arrivalLng,
    });
  }

  CachedVisitsCompanion copyWith(
      {Value<int>? id,
      Value<String>? date,
      Value<int>? orderInRoute,
      Value<String>? status,
      Value<String?>? result,
      Value<String>? json,
      Value<DateTime?>? arrivedAtUtc,
      Value<double?>? arrivalLat,
      Value<double?>? arrivalLng}) {
    return CachedVisitsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      orderInRoute: orderInRoute ?? this.orderInRoute,
      status: status ?? this.status,
      result: result ?? this.result,
      json: json ?? this.json,
      arrivedAtUtc: arrivedAtUtc ?? this.arrivedAtUtc,
      arrivalLat: arrivalLat ?? this.arrivalLat,
      arrivalLng: arrivalLng ?? this.arrivalLng,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (orderInRoute.present) {
      map['order_in_route'] = Variable<int>(orderInRoute.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (arrivedAtUtc.present) {
      map['arrived_at_utc'] = Variable<DateTime>(arrivedAtUtc.value);
    }
    if (arrivalLat.present) {
      map['arrival_lat'] = Variable<double>(arrivalLat.value);
    }
    if (arrivalLng.present) {
      map['arrival_lng'] = Variable<double>(arrivalLng.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVisitsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('orderInRoute: $orderInRoute, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('json: $json, ')
          ..write('arrivedAtUtc: $arrivedAtUtc, ')
          ..write('arrivalLat: $arrivalLat, ')
          ..write('arrivalLng: $arrivalLng')
          ..write(')'))
        .toString();
  }
}

class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitIdMeta =
      const VerificationMeta('visitId');
  @override
  late final GeneratedColumn<int> visitId = GeneratedColumn<int>(
      'visit_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtUtcMeta =
      const VerificationMeta('occurredAtUtc');
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>('occurred_at_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
      'tz', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('America/Mexico_City'));
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _graceUntilUtcMeta =
      const VerificationMeta('graceUntilUtc');
  @override
  late final GeneratedColumn<DateTime> graceUntilUtc =
      GeneratedColumn<DateTime>('grace_until_utc', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uuid,
        seq,
        type,
        visitId,
        occurredAtUtc,
        tz,
        payloadJson,
        state,
        graceUntilUtc,
        attempts,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(_visitIdMeta,
          visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta));
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
          _occurredAtUtcMeta,
          occurredAtUtc.isAcceptableOrUnknown(
              data['occurred_at_utc']!, _occurredAtUtcMeta));
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('grace_until_utc')) {
      context.handle(
          _graceUntilUtcMeta,
          graceUntilUtc.isAcceptableOrUnknown(
              data['grace_until_utc']!, _graceUntilUtcMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEvent(
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      visitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}visit_id']),
      occurredAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}occurred_at_utc'])!,
      tz: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tz'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      graceUntilUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}grace_until_utc']),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxEvent extends DataClass implements Insertable<OutboxEvent> {
  final String uuid;
  final int seq;
  final String type;
  final int? visitId;
  final DateTime occurredAtUtc;
  final String tz;
  final String payloadJson;
  final String state;
  final DateTime? graceUntilUtc;
  final int attempts;
  final String? lastError;
  const OutboxEvent(
      {required this.uuid,
      required this.seq,
      required this.type,
      this.visitId,
      required this.occurredAtUtc,
      required this.tz,
      required this.payloadJson,
      required this.state,
      this.graceUntilUtc,
      required this.attempts,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['seq'] = Variable<int>(seq);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<int>(visitId);
    }
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['tz'] = Variable<String>(tz);
    map['payload_json'] = Variable<String>(payloadJson);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || graceUntilUtc != null) {
      map['grace_until_utc'] = Variable<DateTime>(graceUntilUtc);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      uuid: Value(uuid),
      seq: Value(seq),
      type: Value(type),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      occurredAtUtc: Value(occurredAtUtc),
      tz: Value(tz),
      payloadJson: Value(payloadJson),
      state: Value(state),
      graceUntilUtc: graceUntilUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(graceUntilUtc),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEvent(
      uuid: serializer.fromJson<String>(json['uuid']),
      seq: serializer.fromJson<int>(json['seq']),
      type: serializer.fromJson<String>(json['type']),
      visitId: serializer.fromJson<int?>(json['visitId']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      tz: serializer.fromJson<String>(json['tz']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      state: serializer.fromJson<String>(json['state']),
      graceUntilUtc: serializer.fromJson<DateTime?>(json['graceUntilUtc']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'seq': serializer.toJson<int>(seq),
      'type': serializer.toJson<String>(type),
      'visitId': serializer.toJson<int?>(visitId),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'tz': serializer.toJson<String>(tz),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'state': serializer.toJson<String>(state),
      'graceUntilUtc': serializer.toJson<DateTime?>(graceUntilUtc),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEvent copyWith(
          {String? uuid,
          int? seq,
          String? type,
          Value<int?> visitId = const Value.absent(),
          DateTime? occurredAtUtc,
          String? tz,
          String? payloadJson,
          String? state,
          Value<DateTime?> graceUntilUtc = const Value.absent(),
          int? attempts,
          Value<String?> lastError = const Value.absent()}) =>
      OutboxEvent(
        uuid: uuid ?? this.uuid,
        seq: seq ?? this.seq,
        type: type ?? this.type,
        visitId: visitId.present ? visitId.value : this.visitId,
        occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
        tz: tz ?? this.tz,
        payloadJson: payloadJson ?? this.payloadJson,
        state: state ?? this.state,
        graceUntilUtc:
            graceUntilUtc.present ? graceUntilUtc.value : this.graceUntilUtc,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  OutboxEvent copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEvent(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      seq: data.seq.present ? data.seq.value : this.seq,
      type: data.type.present ? data.type.value : this.type,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      tz: data.tz.present ? data.tz.value : this.tz,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      state: data.state.present ? data.state.value : this.state,
      graceUntilUtc: data.graceUntilUtc.present
          ? data.graceUntilUtc.value
          : this.graceUntilUtc,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEvent(')
          ..write('uuid: $uuid, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('visitId: $visitId, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tz: $tz, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('state: $state, ')
          ..write('graceUntilUtc: $graceUntilUtc, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uuid, seq, type, visitId, occurredAtUtc, tz,
      payloadJson, state, graceUntilUtc, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEvent &&
          other.uuid == this.uuid &&
          other.seq == this.seq &&
          other.type == this.type &&
          other.visitId == this.visitId &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.tz == this.tz &&
          other.payloadJson == this.payloadJson &&
          other.state == this.state &&
          other.graceUntilUtc == this.graceUntilUtc &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEvent> {
  final Value<String> uuid;
  final Value<int> seq;
  final Value<String> type;
  final Value<int?> visitId;
  final Value<DateTime> occurredAtUtc;
  final Value<String> tz;
  final Value<String> payloadJson;
  final Value<String> state;
  final Value<DateTime?> graceUntilUtc;
  final Value<int> attempts;
  final Value<String?> lastError;
  const OutboxEventsCompanion({
    this.uuid = const Value.absent(),
    this.seq = const Value.absent(),
    this.type = const Value.absent(),
    this.visitId = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.tz = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.state = const Value.absent(),
    this.graceUntilUtc = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String uuid,
    this.seq = const Value.absent(),
    required String type,
    this.visitId = const Value.absent(),
    required DateTime occurredAtUtc,
    this.tz = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.state = const Value.absent(),
    this.graceUntilUtc = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  })  : uuid = Value(uuid),
        type = Value(type),
        occurredAtUtc = Value(occurredAtUtc);
  static Insertable<OutboxEvent> custom({
    Expression<String>? uuid,
    Expression<int>? seq,
    Expression<String>? type,
    Expression<int>? visitId,
    Expression<DateTime>? occurredAtUtc,
    Expression<String>? tz,
    Expression<String>? payloadJson,
    Expression<String>? state,
    Expression<DateTime>? graceUntilUtc,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (seq != null) 'seq': seq,
      if (type != null) 'type': type,
      if (visitId != null) 'visit_id': visitId,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (tz != null) 'tz': tz,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (state != null) 'state': state,
      if (graceUntilUtc != null) 'grace_until_utc': graceUntilUtc,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxEventsCompanion copyWith(
      {Value<String>? uuid,
      Value<int>? seq,
      Value<String>? type,
      Value<int?>? visitId,
      Value<DateTime>? occurredAtUtc,
      Value<String>? tz,
      Value<String>? payloadJson,
      Value<String>? state,
      Value<DateTime?>? graceUntilUtc,
      Value<int>? attempts,
      Value<String?>? lastError}) {
    return OutboxEventsCompanion(
      uuid: uuid ?? this.uuid,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      visitId: visitId ?? this.visitId,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      tz: tz ?? this.tz,
      payloadJson: payloadJson ?? this.payloadJson,
      state: state ?? this.state,
      graceUntilUtc: graceUntilUtc ?? this.graceUntilUtc,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<int>(visitId.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (graceUntilUtc.present) {
      map['grace_until_utc'] = Variable<DateTime>(graceUntilUtc.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('visitId: $visitId, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tz: $tz, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('state: $state, ')
          ..write('graceUntilUtc: $graceUntilUtc, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $MediaQueueTable extends MediaQueue
    with TableInfo<$MediaQueueTable, MediaQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitIdMeta =
      const VerificationMeta('visitId');
  @override
  late final GeneratedColumn<int> visitId = GeneratedColumn<int>(
      'visit_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wifiOnlyMeta =
      const VerificationMeta('wifiOnly');
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
      'wifi_only', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wifi_only" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [uuid, visitId, kind, localPath, wifiOnly, state, createdAtUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_queue';
  @override
  VerificationContext validateIntegrity(Insertable<MediaQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(_visitIdMeta,
          visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta));
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('wifi_only')) {
      context.handle(_wifiOnlyMeta,
          wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  MediaQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaQueueData(
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      visitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}visit_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      wifiOnly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}wifi_only'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      createdAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}created_at_utc'])!,
    );
  }

  @override
  $MediaQueueTable createAlias(String alias) {
    return $MediaQueueTable(attachedDatabase, alias);
  }
}

class MediaQueueData extends DataClass implements Insertable<MediaQueueData> {
  final String uuid;
  final int visitId;
  final String kind;
  final String localPath;
  final bool wifiOnly;
  final String state;
  final DateTime createdAtUtc;
  const MediaQueueData(
      {required this.uuid,
      required this.visitId,
      required this.kind,
      required this.localPath,
      required this.wifiOnly,
      required this.state,
      required this.createdAtUtc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['visit_id'] = Variable<int>(visitId);
    map['kind'] = Variable<String>(kind);
    map['local_path'] = Variable<String>(localPath);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['state'] = Variable<String>(state);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  MediaQueueCompanion toCompanion(bool nullToAbsent) {
    return MediaQueueCompanion(
      uuid: Value(uuid),
      visitId: Value(visitId),
      kind: Value(kind),
      localPath: Value(localPath),
      wifiOnly: Value(wifiOnly),
      state: Value(state),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory MediaQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaQueueData(
      uuid: serializer.fromJson<String>(json['uuid']),
      visitId: serializer.fromJson<int>(json['visitId']),
      kind: serializer.fromJson<String>(json['kind']),
      localPath: serializer.fromJson<String>(json['localPath']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      state: serializer.fromJson<String>(json['state']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'visitId': serializer.toJson<int>(visitId),
      'kind': serializer.toJson<String>(kind),
      'localPath': serializer.toJson<String>(localPath),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'state': serializer.toJson<String>(state),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  MediaQueueData copyWith(
          {String? uuid,
          int? visitId,
          String? kind,
          String? localPath,
          bool? wifiOnly,
          String? state,
          DateTime? createdAtUtc}) =>
      MediaQueueData(
        uuid: uuid ?? this.uuid,
        visitId: visitId ?? this.visitId,
        kind: kind ?? this.kind,
        localPath: localPath ?? this.localPath,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        state: state ?? this.state,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      );
  MediaQueueData copyWithCompanion(MediaQueueCompanion data) {
    return MediaQueueData(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      kind: data.kind.present ? data.kind.value : this.kind,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      state: data.state.present ? data.state.value : this.state,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaQueueData(')
          ..write('uuid: $uuid, ')
          ..write('visitId: $visitId, ')
          ..write('kind: $kind, ')
          ..write('localPath: $localPath, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('state: $state, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uuid, visitId, kind, localPath, wifiOnly, state, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaQueueData &&
          other.uuid == this.uuid &&
          other.visitId == this.visitId &&
          other.kind == this.kind &&
          other.localPath == this.localPath &&
          other.wifiOnly == this.wifiOnly &&
          other.state == this.state &&
          other.createdAtUtc == this.createdAtUtc);
}

class MediaQueueCompanion extends UpdateCompanion<MediaQueueData> {
  final Value<String> uuid;
  final Value<int> visitId;
  final Value<String> kind;
  final Value<String> localPath;
  final Value<bool> wifiOnly;
  final Value<String> state;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const MediaQueueCompanion({
    this.uuid = const Value.absent(),
    this.visitId = const Value.absent(),
    this.kind = const Value.absent(),
    this.localPath = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaQueueCompanion.insert({
    required String uuid,
    required int visitId,
    required String kind,
    required String localPath,
    this.wifiOnly = const Value.absent(),
    this.state = const Value.absent(),
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  })  : uuid = Value(uuid),
        visitId = Value(visitId),
        kind = Value(kind),
        localPath = Value(localPath),
        createdAtUtc = Value(createdAtUtc);
  static Insertable<MediaQueueData> custom({
    Expression<String>? uuid,
    Expression<int>? visitId,
    Expression<String>? kind,
    Expression<String>? localPath,
    Expression<bool>? wifiOnly,
    Expression<String>? state,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (visitId != null) 'visit_id': visitId,
      if (kind != null) 'kind': kind,
      if (localPath != null) 'local_path': localPath,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (state != null) 'state': state,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaQueueCompanion copyWith(
      {Value<String>? uuid,
      Value<int>? visitId,
      Value<String>? kind,
      Value<String>? localPath,
      Value<bool>? wifiOnly,
      Value<String>? state,
      Value<DateTime>? createdAtUtc,
      Value<int>? rowid}) {
    return MediaQueueCompanion(
      uuid: uuid ?? this.uuid,
      visitId: visitId ?? this.visitId,
      kind: kind ?? this.kind,
      localPath: localPath ?? this.localPath,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      state: state ?? this.state,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<int>(visitId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaQueueCompanion(')
          ..write('uuid: $uuid, ')
          ..write('visitId: $visitId, ')
          ..write('kind: $kind, ')
          ..write('localPath: $localPath, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('state: $state, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  late final $CachedVisitsTable cachedVisits = $CachedVisitsTable(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $MediaQueueTable mediaQueue = $MediaQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [settingsKv, cachedVisits, outboxEvents, mediaQueue];
}

typedef $$SettingsKvTableCreateCompanionBuilder = SettingsKvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsKvTableUpdateCompanionBuilder = SettingsKvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsKvTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsKvTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsKvTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsKvTable,
    SettingsKvData,
    $$SettingsKvTableFilterComposer,
    $$SettingsKvTableOrderingComposer,
    $$SettingsKvTableAnnotationComposer,
    $$SettingsKvTableCreateCompanionBuilder,
    $$SettingsKvTableUpdateCompanionBuilder,
    (
      SettingsKvData,
      BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>
    ),
    SettingsKvData,
    PrefetchHooks Function()> {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsKvCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsKvCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsKvTable, SettingsKvData>(table),
                    BaseReferences<_$AppDatabase, $SettingsKvTable,
                        SettingsKvData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsKvTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsKvTable,
    SettingsKvData,
    $$SettingsKvTableFilterComposer,
    $$SettingsKvTableOrderingComposer,
    $$SettingsKvTableAnnotationComposer,
    $$SettingsKvTableCreateCompanionBuilder,
    $$SettingsKvTableUpdateCompanionBuilder,
    (
      SettingsKvData,
      BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>
    ),
    SettingsKvData,
    PrefetchHooks Function()>;
typedef $$CachedVisitsTableCreateCompanionBuilder = CachedVisitsCompanion
    Function({
  Value<int> id,
  required String date,
  required int orderInRoute,
  required String status,
  Value<String?> result,
  required String json,
  Value<DateTime?> arrivedAtUtc,
  Value<double?> arrivalLat,
  Value<double?> arrivalLng,
});
typedef $$CachedVisitsTableUpdateCompanionBuilder = CachedVisitsCompanion
    Function({
  Value<int> id,
  Value<String> date,
  Value<int> orderInRoute,
  Value<String> status,
  Value<String?> result,
  Value<String> json,
  Value<DateTime?> arrivedAtUtc,
  Value<double?> arrivalLat,
  Value<double?> arrivalLng,
});

class $$CachedVisitsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedVisitsTable> {
  $$CachedVisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderInRoute => $composableBuilder(
      column: $table.orderInRoute, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get arrivedAtUtc => $composableBuilder(
      column: $table.arrivedAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get arrivalLat => $composableBuilder(
      column: $table.arrivalLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get arrivalLng => $composableBuilder(
      column: $table.arrivalLng, builder: (column) => ColumnFilters(column));
}

class $$CachedVisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedVisitsTable> {
  $$CachedVisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderInRoute => $composableBuilder(
      column: $table.orderInRoute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get arrivedAtUtc => $composableBuilder(
      column: $table.arrivedAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get arrivalLat => $composableBuilder(
      column: $table.arrivalLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get arrivalLng => $composableBuilder(
      column: $table.arrivalLng, builder: (column) => ColumnOrderings(column));
}

class $$CachedVisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedVisitsTable> {
  $$CachedVisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get orderInRoute => $composableBuilder(
      column: $table.orderInRoute, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get arrivedAtUtc => $composableBuilder(
      column: $table.arrivedAtUtc, builder: (column) => column);

  GeneratedColumn<double> get arrivalLat => $composableBuilder(
      column: $table.arrivalLat, builder: (column) => column);

  GeneratedColumn<double> get arrivalLng => $composableBuilder(
      column: $table.arrivalLng, builder: (column) => column);
}

class $$CachedVisitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedVisitsTable,
    CachedVisit,
    $$CachedVisitsTableFilterComposer,
    $$CachedVisitsTableOrderingComposer,
    $$CachedVisitsTableAnnotationComposer,
    $$CachedVisitsTableCreateCompanionBuilder,
    $$CachedVisitsTableUpdateCompanionBuilder,
    (
      CachedVisit,
      BaseReferences<_$AppDatabase, $CachedVisitsTable, CachedVisit>
    ),
    CachedVisit,
    PrefetchHooks Function()> {
  $$CachedVisitsTableTableManager(_$AppDatabase db, $CachedVisitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedVisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedVisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedVisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<int> orderInRoute = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> result = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<DateTime?> arrivedAtUtc = const Value.absent(),
            Value<double?> arrivalLat = const Value.absent(),
            Value<double?> arrivalLng = const Value.absent(),
          }) =>
              CachedVisitsCompanion(
            id: id,
            date: date,
            orderInRoute: orderInRoute,
            status: status,
            result: result,
            json: json,
            arrivedAtUtc: arrivedAtUtc,
            arrivalLat: arrivalLat,
            arrivalLng: arrivalLng,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String date,
            required int orderInRoute,
            required String status,
            Value<String?> result = const Value.absent(),
            required String json,
            Value<DateTime?> arrivedAtUtc = const Value.absent(),
            Value<double?> arrivalLat = const Value.absent(),
            Value<double?> arrivalLng = const Value.absent(),
          }) =>
              CachedVisitsCompanion.insert(
            id: id,
            date: date,
            orderInRoute: orderInRoute,
            status: status,
            result: result,
            json: json,
            arrivedAtUtc: arrivedAtUtc,
            arrivalLat: arrivalLat,
            arrivalLng: arrivalLng,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CachedVisitsTable, CachedVisit>(table),
                    BaseReferences<_$AppDatabase, $CachedVisitsTable,
                        CachedVisit>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedVisitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedVisitsTable,
    CachedVisit,
    $$CachedVisitsTableFilterComposer,
    $$CachedVisitsTableOrderingComposer,
    $$CachedVisitsTableAnnotationComposer,
    $$CachedVisitsTableCreateCompanionBuilder,
    $$CachedVisitsTableUpdateCompanionBuilder,
    (
      CachedVisit,
      BaseReferences<_$AppDatabase, $CachedVisitsTable, CachedVisit>
    ),
    CachedVisit,
    PrefetchHooks Function()>;
typedef $$OutboxEventsTableCreateCompanionBuilder = OutboxEventsCompanion
    Function({
  required String uuid,
  Value<int> seq,
  required String type,
  Value<int?> visitId,
  required DateTime occurredAtUtc,
  Value<String> tz,
  Value<String> payloadJson,
  Value<String> state,
  Value<DateTime?> graceUntilUtc,
  Value<int> attempts,
  Value<String?> lastError,
});
typedef $$OutboxEventsTableUpdateCompanionBuilder = OutboxEventsCompanion
    Function({
  Value<String> uuid,
  Value<int> seq,
  Value<String> type,
  Value<int?> visitId,
  Value<DateTime> occurredAtUtc,
  Value<String> tz,
  Value<String> payloadJson,
  Value<String> state,
  Value<DateTime?> graceUntilUtc,
  Value<int> attempts,
  Value<String?> lastError,
});

class $$OutboxEventsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get graceUntilUtc => $composableBuilder(
      column: $table.graceUntilUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get graceUntilUtc => $composableBuilder(
      column: $table.graceUntilUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get graceUntilUtc => $composableBuilder(
      column: $table.graceUntilUtc, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxEventsTable,
    OutboxEvent,
    $$OutboxEventsTableFilterComposer,
    $$OutboxEventsTableOrderingComposer,
    $$OutboxEventsTableAnnotationComposer,
    $$OutboxEventsTableCreateCompanionBuilder,
    $$OutboxEventsTableUpdateCompanionBuilder,
    (
      OutboxEvent,
      BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>
    ),
    OutboxEvent,
    PrefetchHooks Function()> {
  $$OutboxEventsTableTableManager(_$AppDatabase db, $OutboxEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uuid = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int?> visitId = const Value.absent(),
            Value<DateTime> occurredAtUtc = const Value.absent(),
            Value<String> tz = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<DateTime?> graceUntilUtc = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              OutboxEventsCompanion(
            uuid: uuid,
            seq: seq,
            type: type,
            visitId: visitId,
            occurredAtUtc: occurredAtUtc,
            tz: tz,
            payloadJson: payloadJson,
            state: state,
            graceUntilUtc: graceUntilUtc,
            attempts: attempts,
            lastError: lastError,
          ),
          createCompanionCallback: ({
            required String uuid,
            Value<int> seq = const Value.absent(),
            required String type,
            Value<int?> visitId = const Value.absent(),
            required DateTime occurredAtUtc,
            Value<String> tz = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<DateTime?> graceUntilUtc = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              OutboxEventsCompanion.insert(
            uuid: uuid,
            seq: seq,
            type: type,
            visitId: visitId,
            occurredAtUtc: occurredAtUtc,
            tz: tz,
            payloadJson: payloadJson,
            state: state,
            graceUntilUtc: graceUntilUtc,
            attempts: attempts,
            lastError: lastError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$OutboxEventsTable, OutboxEvent>(table),
                    BaseReferences<_$AppDatabase, $OutboxEventsTable,
                        OutboxEvent>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxEventsTable,
    OutboxEvent,
    $$OutboxEventsTableFilterComposer,
    $$OutboxEventsTableOrderingComposer,
    $$OutboxEventsTableAnnotationComposer,
    $$OutboxEventsTableCreateCompanionBuilder,
    $$OutboxEventsTableUpdateCompanionBuilder,
    (
      OutboxEvent,
      BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>
    ),
    OutboxEvent,
    PrefetchHooks Function()>;
typedef $$MediaQueueTableCreateCompanionBuilder = MediaQueueCompanion Function({
  required String uuid,
  required int visitId,
  required String kind,
  required String localPath,
  Value<bool> wifiOnly,
  Value<String> state,
  required DateTime createdAtUtc,
  Value<int> rowid,
});
typedef $$MediaQueueTableUpdateCompanionBuilder = MediaQueueCompanion Function({
  Value<String> uuid,
  Value<int> visitId,
  Value<String> kind,
  Value<String> localPath,
  Value<bool> wifiOnly,
  Value<String> state,
  Value<DateTime> createdAtUtc,
  Value<int> rowid,
});

class $$MediaQueueTableFilterComposer
    extends Composer<_$AppDatabase, $MediaQueueTable> {
  $$MediaQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));
}

class $$MediaQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaQueueTable> {
  $$MediaQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));
}

class $$MediaQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaQueueTable> {
  $$MediaQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);
}

class $$MediaQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaQueueTable,
    MediaQueueData,
    $$MediaQueueTableFilterComposer,
    $$MediaQueueTableOrderingComposer,
    $$MediaQueueTableAnnotationComposer,
    $$MediaQueueTableCreateCompanionBuilder,
    $$MediaQueueTableUpdateCompanionBuilder,
    (
      MediaQueueData,
      BaseReferences<_$AppDatabase, $MediaQueueTable, MediaQueueData>
    ),
    MediaQueueData,
    PrefetchHooks Function()> {
  $$MediaQueueTableTableManager(_$AppDatabase db, $MediaQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uuid = const Value.absent(),
            Value<int> visitId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<bool> wifiOnly = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<DateTime> createdAtUtc = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaQueueCompanion(
            uuid: uuid,
            visitId: visitId,
            kind: kind,
            localPath: localPath,
            wifiOnly: wifiOnly,
            state: state,
            createdAtUtc: createdAtUtc,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uuid,
            required int visitId,
            required String kind,
            required String localPath,
            Value<bool> wifiOnly = const Value.absent(),
            Value<String> state = const Value.absent(),
            required DateTime createdAtUtc,
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaQueueCompanion.insert(
            uuid: uuid,
            visitId: visitId,
            kind: kind,
            localPath: localPath,
            wifiOnly: wifiOnly,
            state: state,
            createdAtUtc: createdAtUtc,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MediaQueueTable, MediaQueueData>(table),
                    BaseReferences<_$AppDatabase, $MediaQueueTable,
                        MediaQueueData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaQueueTable,
    MediaQueueData,
    $$MediaQueueTableFilterComposer,
    $$MediaQueueTableOrderingComposer,
    $$MediaQueueTableAnnotationComposer,
    $$MediaQueueTableCreateCompanionBuilder,
    $$MediaQueueTableUpdateCompanionBuilder,
    (
      MediaQueueData,
      BaseReferences<_$AppDatabase, $MediaQueueTable, MediaQueueData>
    ),
    MediaQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
  $$CachedVisitsTableTableManager get cachedVisits =>
      $$CachedVisitsTableTableManager(_db, _db.cachedVisits);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$MediaQueueTableTableManager get mediaQueue =>
      $$MediaQueueTableTableManager(_db, _db.mediaQueue);
}
