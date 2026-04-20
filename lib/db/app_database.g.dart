// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GazesTable extends Gazes with TableInfo<$GazesTable, Gaze> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GazesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompactMeta = const VerificationMeta(
    'isCompact',
  );
  @override
  late final GeneratedColumn<bool> isCompact = GeneratedColumn<bool>(
    'is_compact',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_compact" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDoublePrimaryMeta = const VerificationMeta(
    'isDoublePrimary',
  );
  @override
  late final GeneratedColumn<bool> isDoublePrimary = GeneratedColumn<bool>(
    'is_double_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_double_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    notes,
    isCompact,
    isDoublePrimary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gazes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Gaze> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_compact')) {
      context.handle(
        _isCompactMeta,
        isCompact.isAcceptableOrUnknown(data['is_compact']!, _isCompactMeta),
      );
    }
    if (data.containsKey('is_double_primary')) {
      context.handle(
        _isDoublePrimaryMeta,
        isDoublePrimary.isAcceptableOrUnknown(
          data['is_double_primary']!,
          _isDoublePrimaryMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Gaze map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Gaze(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isCompact: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_compact'],
      )!,
      isDoublePrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_double_primary'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GazesTable createAlias(String alias) {
    return $GazesTable(attachedDatabase, alias);
  }
}

class Gaze extends DataClass implements Insertable<Gaze> {
  final int id;
  final String name;
  final String? notes;
  final bool isCompact;
  final bool isDoublePrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Gaze({
    required this.id,
    required this.name,
    this.notes,
    required this.isCompact,
    required this.isDoublePrimary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_compact'] = Variable<bool>(isCompact);
    map['is_double_primary'] = Variable<bool>(isDoublePrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GazesCompanion toCompanion(bool nullToAbsent) {
    return GazesCompanion(
      id: Value(id),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isCompact: Value(isCompact),
      isDoublePrimary: Value(isDoublePrimary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Gaze.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Gaze(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isCompact: serializer.fromJson<bool>(json['isCompact']),
      isDoublePrimary: serializer.fromJson<bool>(json['isDoublePrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isCompact': serializer.toJson<bool>(isCompact),
      'isDoublePrimary': serializer.toJson<bool>(isDoublePrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Gaze copyWith({
    int? id,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isCompact,
    bool? isDoublePrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Gaze(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isCompact: isCompact ?? this.isCompact,
    isDoublePrimary: isDoublePrimary ?? this.isDoublePrimary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Gaze copyWithCompanion(GazesCompanion data) {
    return Gaze(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isCompact: data.isCompact.present ? data.isCompact.value : this.isCompact,
      isDoublePrimary: data.isDoublePrimary.present
          ? data.isDoublePrimary.value
          : this.isDoublePrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Gaze(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isCompact: $isCompact, ')
          ..write('isDoublePrimary: $isDoublePrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    notes,
    isCompact,
    isDoublePrimary,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Gaze &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isCompact == this.isCompact &&
          other.isDoublePrimary == this.isDoublePrimary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GazesCompanion extends UpdateCompanion<Gaze> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isCompact;
  final Value<bool> isDoublePrimary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GazesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCompact = const Value.absent(),
    this.isDoublePrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GazesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.isCompact = const Value.absent(),
    this.isDoublePrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Gaze> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isCompact,
    Expression<bool>? isDoublePrimary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isCompact != null) 'is_compact': isCompact,
      if (isDoublePrimary != null) 'is_double_primary': isDoublePrimary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GazesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isCompact,
    Value<bool>? isDoublePrimary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GazesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isCompact: isCompact ?? this.isCompact,
      isDoublePrimary: isDoublePrimary ?? this.isDoublePrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isCompact.present) {
      map['is_compact'] = Variable<bool>(isCompact.value);
    }
    if (isDoublePrimary.present) {
      map['is_double_primary'] = Variable<bool>(isDoublePrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GazesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isCompact: $isCompact, ')
          ..write('isDoublePrimary: $isDoublePrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GazeSlotsTable extends GazeSlots
    with TableInfo<$GazeSlotsTable, GazeSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GazeSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gazeIdMeta = const VerificationMeta('gazeId');
  @override
  late final GeneratedColumn<int> gazeId = GeneratedColumn<int>(
    'gaze_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gazes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _slotKeyMeta = const VerificationMeta(
    'slotKey',
  );
  @override
  late final GeneratedColumn<String> slotKey = GeneratedColumn<String>(
    'slot_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translateXMeta = const VerificationMeta(
    'translateX',
  );
  @override
  late final GeneratedColumn<double> translateX = GeneratedColumn<double>(
    'translate_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _translateYMeta = const VerificationMeta(
    'translateY',
  );
  @override
  late final GeneratedColumn<double> translateY = GeneratedColumn<double>(
    'translate_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<double> scale = GeneratedColumn<double>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _eyeLeftXMeta = const VerificationMeta(
    'eyeLeftX',
  );
  @override
  late final GeneratedColumn<double> eyeLeftX = GeneratedColumn<double>(
    'eye_left_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eyeLeftYMeta = const VerificationMeta(
    'eyeLeftY',
  );
  @override
  late final GeneratedColumn<double> eyeLeftY = GeneratedColumn<double>(
    'eye_left_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eyeRightXMeta = const VerificationMeta(
    'eyeRightX',
  );
  @override
  late final GeneratedColumn<double> eyeRightX = GeneratedColumn<double>(
    'eye_right_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eyeRightYMeta = const VerificationMeta(
    'eyeRightY',
  );
  @override
  late final GeneratedColumn<double> eyeRightY = GeneratedColumn<double>(
    'eye_right_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceWidthMeta = const VerificationMeta(
    'sourceWidth',
  );
  @override
  late final GeneratedColumn<int> sourceWidth = GeneratedColumn<int>(
    'source_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceHeightMeta = const VerificationMeta(
    'sourceHeight',
  );
  @override
  late final GeneratedColumn<int> sourceHeight = GeneratedColumn<int>(
    'source_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gazeId,
    slotKey,
    imagePath,
    translateX,
    translateY,
    scale,
    rotation,
    eyeLeftX,
    eyeLeftY,
    eyeRightX,
    eyeRightY,
    sourceWidth,
    sourceHeight,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gaze_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<GazeSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('gaze_id')) {
      context.handle(
        _gazeIdMeta,
        gazeId.isAcceptableOrUnknown(data['gaze_id']!, _gazeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gazeIdMeta);
    }
    if (data.containsKey('slot_key')) {
      context.handle(
        _slotKeyMeta,
        slotKey.isAcceptableOrUnknown(data['slot_key']!, _slotKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_slotKeyMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('translate_x')) {
      context.handle(
        _translateXMeta,
        translateX.isAcceptableOrUnknown(data['translate_x']!, _translateXMeta),
      );
    }
    if (data.containsKey('translate_y')) {
      context.handle(
        _translateYMeta,
        translateY.isAcceptableOrUnknown(data['translate_y']!, _translateYMeta),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('eye_left_x')) {
      context.handle(
        _eyeLeftXMeta,
        eyeLeftX.isAcceptableOrUnknown(data['eye_left_x']!, _eyeLeftXMeta),
      );
    }
    if (data.containsKey('eye_left_y')) {
      context.handle(
        _eyeLeftYMeta,
        eyeLeftY.isAcceptableOrUnknown(data['eye_left_y']!, _eyeLeftYMeta),
      );
    }
    if (data.containsKey('eye_right_x')) {
      context.handle(
        _eyeRightXMeta,
        eyeRightX.isAcceptableOrUnknown(data['eye_right_x']!, _eyeRightXMeta),
      );
    }
    if (data.containsKey('eye_right_y')) {
      context.handle(
        _eyeRightYMeta,
        eyeRightY.isAcceptableOrUnknown(data['eye_right_y']!, _eyeRightYMeta),
      );
    }
    if (data.containsKey('source_width')) {
      context.handle(
        _sourceWidthMeta,
        sourceWidth.isAcceptableOrUnknown(
          data['source_width']!,
          _sourceWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceWidthMeta);
    }
    if (data.containsKey('source_height')) {
      context.handle(
        _sourceHeightMeta,
        sourceHeight.isAcceptableOrUnknown(
          data['source_height']!,
          _sourceHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceHeightMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gazeId, slotKey},
  ];
  @override
  GazeSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GazeSlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gazeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gaze_id'],
      )!,
      slotKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_key'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      translateX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}translate_x'],
      )!,
      translateY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}translate_y'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scale'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      eyeLeftX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}eye_left_x'],
      ),
      eyeLeftY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}eye_left_y'],
      ),
      eyeRightX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}eye_right_x'],
      ),
      eyeRightY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}eye_right_y'],
      ),
      sourceWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_width'],
      )!,
      sourceHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_height'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GazeSlotsTable createAlias(String alias) {
    return $GazeSlotsTable(attachedDatabase, alias);
  }
}

class GazeSlot extends DataClass implements Insertable<GazeSlot> {
  final int id;

  /// References the parent gaze session; deleting a gaze cascades
  /// to all of its slots.
  final int gazeId;

  /// String value of the SlotKey enum (e.g. "primary", "elevation").
  final String slotKey;

  /// Relative file path under the app documents directory.
  final String imagePath;

  /// Normalised horizontal centre of the image within the slot
  /// frame. 0 = left edge, 1 = right edge, 0.5 = centred.
  final double translateX;

  /// Normalised vertical centre of the image within the slot
  /// frame. 0 = top edge, 1 = bottom edge, 0.5 = centred.
  final double translateY;

  /// User-applied scale multiplier on top of the ML auto-fit base
  /// scale. 1.0 = exactly the recommended fit.
  final double scale;

  /// Clockwise rotation in radians applied after scale.
  final double rotation;

  /// Left-eye X position normalised to source image width (0–1).
  final double? eyeLeftX;

  /// Left-eye Y position normalised to source image height (0–1).
  final double? eyeLeftY;

  /// Right-eye X position normalised to source image width (0–1).
  final double? eyeRightX;

  /// Right-eye Y position normalised to source image height (0–1).
  final double? eyeRightY;

  /// Width of the source image in pixels.
  final int sourceWidth;

  /// Height of the source image in pixels.
  final int sourceHeight;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GazeSlot({
    required this.id,
    required this.gazeId,
    required this.slotKey,
    required this.imagePath,
    required this.translateX,
    required this.translateY,
    required this.scale,
    required this.rotation,
    this.eyeLeftX,
    this.eyeLeftY,
    this.eyeRightX,
    this.eyeRightY,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['gaze_id'] = Variable<int>(gazeId);
    map['slot_key'] = Variable<String>(slotKey);
    map['image_path'] = Variable<String>(imagePath);
    map['translate_x'] = Variable<double>(translateX);
    map['translate_y'] = Variable<double>(translateY);
    map['scale'] = Variable<double>(scale);
    map['rotation'] = Variable<double>(rotation);
    if (!nullToAbsent || eyeLeftX != null) {
      map['eye_left_x'] = Variable<double>(eyeLeftX);
    }
    if (!nullToAbsent || eyeLeftY != null) {
      map['eye_left_y'] = Variable<double>(eyeLeftY);
    }
    if (!nullToAbsent || eyeRightX != null) {
      map['eye_right_x'] = Variable<double>(eyeRightX);
    }
    if (!nullToAbsent || eyeRightY != null) {
      map['eye_right_y'] = Variable<double>(eyeRightY);
    }
    map['source_width'] = Variable<int>(sourceWidth);
    map['source_height'] = Variable<int>(sourceHeight);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GazeSlotsCompanion toCompanion(bool nullToAbsent) {
    return GazeSlotsCompanion(
      id: Value(id),
      gazeId: Value(gazeId),
      slotKey: Value(slotKey),
      imagePath: Value(imagePath),
      translateX: Value(translateX),
      translateY: Value(translateY),
      scale: Value(scale),
      rotation: Value(rotation),
      eyeLeftX: eyeLeftX == null && nullToAbsent
          ? const Value.absent()
          : Value(eyeLeftX),
      eyeLeftY: eyeLeftY == null && nullToAbsent
          ? const Value.absent()
          : Value(eyeLeftY),
      eyeRightX: eyeRightX == null && nullToAbsent
          ? const Value.absent()
          : Value(eyeRightX),
      eyeRightY: eyeRightY == null && nullToAbsent
          ? const Value.absent()
          : Value(eyeRightY),
      sourceWidth: Value(sourceWidth),
      sourceHeight: Value(sourceHeight),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GazeSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GazeSlot(
      id: serializer.fromJson<int>(json['id']),
      gazeId: serializer.fromJson<int>(json['gazeId']),
      slotKey: serializer.fromJson<String>(json['slotKey']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      translateX: serializer.fromJson<double>(json['translateX']),
      translateY: serializer.fromJson<double>(json['translateY']),
      scale: serializer.fromJson<double>(json['scale']),
      rotation: serializer.fromJson<double>(json['rotation']),
      eyeLeftX: serializer.fromJson<double?>(json['eyeLeftX']),
      eyeLeftY: serializer.fromJson<double?>(json['eyeLeftY']),
      eyeRightX: serializer.fromJson<double?>(json['eyeRightX']),
      eyeRightY: serializer.fromJson<double?>(json['eyeRightY']),
      sourceWidth: serializer.fromJson<int>(json['sourceWidth']),
      sourceHeight: serializer.fromJson<int>(json['sourceHeight']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gazeId': serializer.toJson<int>(gazeId),
      'slotKey': serializer.toJson<String>(slotKey),
      'imagePath': serializer.toJson<String>(imagePath),
      'translateX': serializer.toJson<double>(translateX),
      'translateY': serializer.toJson<double>(translateY),
      'scale': serializer.toJson<double>(scale),
      'rotation': serializer.toJson<double>(rotation),
      'eyeLeftX': serializer.toJson<double?>(eyeLeftX),
      'eyeLeftY': serializer.toJson<double?>(eyeLeftY),
      'eyeRightX': serializer.toJson<double?>(eyeRightX),
      'eyeRightY': serializer.toJson<double?>(eyeRightY),
      'sourceWidth': serializer.toJson<int>(sourceWidth),
      'sourceHeight': serializer.toJson<int>(sourceHeight),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GazeSlot copyWith({
    int? id,
    int? gazeId,
    String? slotKey,
    String? imagePath,
    double? translateX,
    double? translateY,
    double? scale,
    double? rotation,
    Value<double?> eyeLeftX = const Value.absent(),
    Value<double?> eyeLeftY = const Value.absent(),
    Value<double?> eyeRightX = const Value.absent(),
    Value<double?> eyeRightY = const Value.absent(),
    int? sourceWidth,
    int? sourceHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GazeSlot(
    id: id ?? this.id,
    gazeId: gazeId ?? this.gazeId,
    slotKey: slotKey ?? this.slotKey,
    imagePath: imagePath ?? this.imagePath,
    translateX: translateX ?? this.translateX,
    translateY: translateY ?? this.translateY,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    eyeLeftX: eyeLeftX.present ? eyeLeftX.value : this.eyeLeftX,
    eyeLeftY: eyeLeftY.present ? eyeLeftY.value : this.eyeLeftY,
    eyeRightX: eyeRightX.present ? eyeRightX.value : this.eyeRightX,
    eyeRightY: eyeRightY.present ? eyeRightY.value : this.eyeRightY,
    sourceWidth: sourceWidth ?? this.sourceWidth,
    sourceHeight: sourceHeight ?? this.sourceHeight,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GazeSlot copyWithCompanion(GazeSlotsCompanion data) {
    return GazeSlot(
      id: data.id.present ? data.id.value : this.id,
      gazeId: data.gazeId.present ? data.gazeId.value : this.gazeId,
      slotKey: data.slotKey.present ? data.slotKey.value : this.slotKey,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      translateX: data.translateX.present
          ? data.translateX.value
          : this.translateX,
      translateY: data.translateY.present
          ? data.translateY.value
          : this.translateY,
      scale: data.scale.present ? data.scale.value : this.scale,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      eyeLeftX: data.eyeLeftX.present ? data.eyeLeftX.value : this.eyeLeftX,
      eyeLeftY: data.eyeLeftY.present ? data.eyeLeftY.value : this.eyeLeftY,
      eyeRightX: data.eyeRightX.present ? data.eyeRightX.value : this.eyeRightX,
      eyeRightY: data.eyeRightY.present ? data.eyeRightY.value : this.eyeRightY,
      sourceWidth: data.sourceWidth.present
          ? data.sourceWidth.value
          : this.sourceWidth,
      sourceHeight: data.sourceHeight.present
          ? data.sourceHeight.value
          : this.sourceHeight,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GazeSlot(')
          ..write('id: $id, ')
          ..write('gazeId: $gazeId, ')
          ..write('slotKey: $slotKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('translateX: $translateX, ')
          ..write('translateY: $translateY, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('eyeLeftX: $eyeLeftX, ')
          ..write('eyeLeftY: $eyeLeftY, ')
          ..write('eyeRightX: $eyeRightX, ')
          ..write('eyeRightY: $eyeRightY, ')
          ..write('sourceWidth: $sourceWidth, ')
          ..write('sourceHeight: $sourceHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gazeId,
    slotKey,
    imagePath,
    translateX,
    translateY,
    scale,
    rotation,
    eyeLeftX,
    eyeLeftY,
    eyeRightX,
    eyeRightY,
    sourceWidth,
    sourceHeight,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GazeSlot &&
          other.id == this.id &&
          other.gazeId == this.gazeId &&
          other.slotKey == this.slotKey &&
          other.imagePath == this.imagePath &&
          other.translateX == this.translateX &&
          other.translateY == this.translateY &&
          other.scale == this.scale &&
          other.rotation == this.rotation &&
          other.eyeLeftX == this.eyeLeftX &&
          other.eyeLeftY == this.eyeLeftY &&
          other.eyeRightX == this.eyeRightX &&
          other.eyeRightY == this.eyeRightY &&
          other.sourceWidth == this.sourceWidth &&
          other.sourceHeight == this.sourceHeight &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GazeSlotsCompanion extends UpdateCompanion<GazeSlot> {
  final Value<int> id;
  final Value<int> gazeId;
  final Value<String> slotKey;
  final Value<String> imagePath;
  final Value<double> translateX;
  final Value<double> translateY;
  final Value<double> scale;
  final Value<double> rotation;
  final Value<double?> eyeLeftX;
  final Value<double?> eyeLeftY;
  final Value<double?> eyeRightX;
  final Value<double?> eyeRightY;
  final Value<int> sourceWidth;
  final Value<int> sourceHeight;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GazeSlotsCompanion({
    this.id = const Value.absent(),
    this.gazeId = const Value.absent(),
    this.slotKey = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.translateX = const Value.absent(),
    this.translateY = const Value.absent(),
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.eyeLeftX = const Value.absent(),
    this.eyeLeftY = const Value.absent(),
    this.eyeRightX = const Value.absent(),
    this.eyeRightY = const Value.absent(),
    this.sourceWidth = const Value.absent(),
    this.sourceHeight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GazeSlotsCompanion.insert({
    this.id = const Value.absent(),
    required int gazeId,
    required String slotKey,
    required String imagePath,
    this.translateX = const Value.absent(),
    this.translateY = const Value.absent(),
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.eyeLeftX = const Value.absent(),
    this.eyeLeftY = const Value.absent(),
    this.eyeRightX = const Value.absent(),
    this.eyeRightY = const Value.absent(),
    required int sourceWidth,
    required int sourceHeight,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : gazeId = Value(gazeId),
       slotKey = Value(slotKey),
       imagePath = Value(imagePath),
       sourceWidth = Value(sourceWidth),
       sourceHeight = Value(sourceHeight);
  static Insertable<GazeSlot> custom({
    Expression<int>? id,
    Expression<int>? gazeId,
    Expression<String>? slotKey,
    Expression<String>? imagePath,
    Expression<double>? translateX,
    Expression<double>? translateY,
    Expression<double>? scale,
    Expression<double>? rotation,
    Expression<double>? eyeLeftX,
    Expression<double>? eyeLeftY,
    Expression<double>? eyeRightX,
    Expression<double>? eyeRightY,
    Expression<int>? sourceWidth,
    Expression<int>? sourceHeight,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gazeId != null) 'gaze_id': gazeId,
      if (slotKey != null) 'slot_key': slotKey,
      if (imagePath != null) 'image_path': imagePath,
      if (translateX != null) 'translate_x': translateX,
      if (translateY != null) 'translate_y': translateY,
      if (scale != null) 'scale': scale,
      if (rotation != null) 'rotation': rotation,
      if (eyeLeftX != null) 'eye_left_x': eyeLeftX,
      if (eyeLeftY != null) 'eye_left_y': eyeLeftY,
      if (eyeRightX != null) 'eye_right_x': eyeRightX,
      if (eyeRightY != null) 'eye_right_y': eyeRightY,
      if (sourceWidth != null) 'source_width': sourceWidth,
      if (sourceHeight != null) 'source_height': sourceHeight,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GazeSlotsCompanion copyWith({
    Value<int>? id,
    Value<int>? gazeId,
    Value<String>? slotKey,
    Value<String>? imagePath,
    Value<double>? translateX,
    Value<double>? translateY,
    Value<double>? scale,
    Value<double>? rotation,
    Value<double?>? eyeLeftX,
    Value<double?>? eyeLeftY,
    Value<double?>? eyeRightX,
    Value<double?>? eyeRightY,
    Value<int>? sourceWidth,
    Value<int>? sourceHeight,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GazeSlotsCompanion(
      id: id ?? this.id,
      gazeId: gazeId ?? this.gazeId,
      slotKey: slotKey ?? this.slotKey,
      imagePath: imagePath ?? this.imagePath,
      translateX: translateX ?? this.translateX,
      translateY: translateY ?? this.translateY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      eyeLeftX: eyeLeftX ?? this.eyeLeftX,
      eyeLeftY: eyeLeftY ?? this.eyeLeftY,
      eyeRightX: eyeRightX ?? this.eyeRightX,
      eyeRightY: eyeRightY ?? this.eyeRightY,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gazeId.present) {
      map['gaze_id'] = Variable<int>(gazeId.value);
    }
    if (slotKey.present) {
      map['slot_key'] = Variable<String>(slotKey.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (translateX.present) {
      map['translate_x'] = Variable<double>(translateX.value);
    }
    if (translateY.present) {
      map['translate_y'] = Variable<double>(translateY.value);
    }
    if (scale.present) {
      map['scale'] = Variable<double>(scale.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (eyeLeftX.present) {
      map['eye_left_x'] = Variable<double>(eyeLeftX.value);
    }
    if (eyeLeftY.present) {
      map['eye_left_y'] = Variable<double>(eyeLeftY.value);
    }
    if (eyeRightX.present) {
      map['eye_right_x'] = Variable<double>(eyeRightX.value);
    }
    if (eyeRightY.present) {
      map['eye_right_y'] = Variable<double>(eyeRightY.value);
    }
    if (sourceWidth.present) {
      map['source_width'] = Variable<int>(sourceWidth.value);
    }
    if (sourceHeight.present) {
      map['source_height'] = Variable<int>(sourceHeight.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GazeSlotsCompanion(')
          ..write('id: $id, ')
          ..write('gazeId: $gazeId, ')
          ..write('slotKey: $slotKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('translateX: $translateX, ')
          ..write('translateY: $translateY, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('eyeLeftX: $eyeLeftX, ')
          ..write('eyeLeftY: $eyeLeftY, ')
          ..write('eyeRightX: $eyeRightX, ')
          ..write('eyeRightY: $eyeRightY, ')
          ..write('sourceWidth: $sourceWidth, ')
          ..write('sourceHeight: $sourceHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GazesTable gazes = $GazesTable(this);
  late final $GazeSlotsTable gazeSlots = $GazeSlotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [gazes, gazeSlots];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'gazes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gaze_slots', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GazesTableCreateCompanionBuilder =
    GazesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> notes,
      Value<bool> isCompact,
      Value<bool> isDoublePrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GazesTableUpdateCompanionBuilder =
    GazesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> notes,
      Value<bool> isCompact,
      Value<bool> isDoublePrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GazesTableReferences
    extends BaseReferences<_$AppDatabase, $GazesTable, Gaze> {
  $$GazesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GazeSlotsTable, List<GazeSlot>>
  _gazeSlotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gazeSlots,
    aliasName: $_aliasNameGenerator(db.gazes.id, db.gazeSlots.gazeId),
  );

  $$GazeSlotsTableProcessedTableManager get gazeSlotsRefs {
    final manager = $$GazeSlotsTableTableManager(
      $_db,
      $_db.gazeSlots,
    ).filter((f) => f.gazeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gazeSlotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GazesTableFilterComposer extends Composer<_$AppDatabase, $GazesTable> {
  $$GazesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompact => $composableBuilder(
    column: $table.isCompact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDoublePrimary => $composableBuilder(
    column: $table.isDoublePrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> gazeSlotsRefs(
    Expression<bool> Function($$GazeSlotsTableFilterComposer f) f,
  ) {
    final $$GazeSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gazeSlots,
      getReferencedColumn: (t) => t.gazeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GazeSlotsTableFilterComposer(
            $db: $db,
            $table: $db.gazeSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GazesTableOrderingComposer
    extends Composer<_$AppDatabase, $GazesTable> {
  $$GazesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompact => $composableBuilder(
    column: $table.isCompact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDoublePrimary => $composableBuilder(
    column: $table.isDoublePrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GazesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GazesTable> {
  $$GazesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isCompact =>
      $composableBuilder(column: $table.isCompact, builder: (column) => column);

  GeneratedColumn<bool> get isDoublePrimary => $composableBuilder(
    column: $table.isDoublePrimary,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> gazeSlotsRefs<T extends Object>(
    Expression<T> Function($$GazeSlotsTableAnnotationComposer a) f,
  ) {
    final $$GazeSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gazeSlots,
      getReferencedColumn: (t) => t.gazeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GazeSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.gazeSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GazesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GazesTable,
          Gaze,
          $$GazesTableFilterComposer,
          $$GazesTableOrderingComposer,
          $$GazesTableAnnotationComposer,
          $$GazesTableCreateCompanionBuilder,
          $$GazesTableUpdateCompanionBuilder,
          (Gaze, $$GazesTableReferences),
          Gaze,
          PrefetchHooks Function({bool gazeSlotsRefs})
        > {
  $$GazesTableTableManager(_$AppDatabase db, $GazesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GazesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GazesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GazesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isCompact = const Value.absent(),
                Value<bool> isDoublePrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GazesCompanion(
                id: id,
                name: name,
                notes: notes,
                isCompact: isCompact,
                isDoublePrimary: isDoublePrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isCompact = const Value.absent(),
                Value<bool> isDoublePrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GazesCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                isCompact: isCompact,
                isDoublePrimary: isDoublePrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GazesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({gazeSlotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gazeSlotsRefs) db.gazeSlots],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gazeSlotsRefs)
                    await $_getPrefetchedData<Gaze, $GazesTable, GazeSlot>(
                      currentTable: table,
                      referencedTable: $$GazesTableReferences
                          ._gazeSlotsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GazesTableReferences(db, table, p0).gazeSlotsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.gazeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GazesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GazesTable,
      Gaze,
      $$GazesTableFilterComposer,
      $$GazesTableOrderingComposer,
      $$GazesTableAnnotationComposer,
      $$GazesTableCreateCompanionBuilder,
      $$GazesTableUpdateCompanionBuilder,
      (Gaze, $$GazesTableReferences),
      Gaze,
      PrefetchHooks Function({bool gazeSlotsRefs})
    >;
typedef $$GazeSlotsTableCreateCompanionBuilder =
    GazeSlotsCompanion Function({
      Value<int> id,
      required int gazeId,
      required String slotKey,
      required String imagePath,
      Value<double> translateX,
      Value<double> translateY,
      Value<double> scale,
      Value<double> rotation,
      Value<double?> eyeLeftX,
      Value<double?> eyeLeftY,
      Value<double?> eyeRightX,
      Value<double?> eyeRightY,
      required int sourceWidth,
      required int sourceHeight,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GazeSlotsTableUpdateCompanionBuilder =
    GazeSlotsCompanion Function({
      Value<int> id,
      Value<int> gazeId,
      Value<String> slotKey,
      Value<String> imagePath,
      Value<double> translateX,
      Value<double> translateY,
      Value<double> scale,
      Value<double> rotation,
      Value<double?> eyeLeftX,
      Value<double?> eyeLeftY,
      Value<double?> eyeRightX,
      Value<double?> eyeRightY,
      Value<int> sourceWidth,
      Value<int> sourceHeight,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GazeSlotsTableReferences
    extends BaseReferences<_$AppDatabase, $GazeSlotsTable, GazeSlot> {
  $$GazeSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GazesTable _gazeIdTable(_$AppDatabase db) => db.gazes.createAlias(
    $_aliasNameGenerator(db.gazeSlots.gazeId, db.gazes.id),
  );

  $$GazesTableProcessedTableManager get gazeId {
    final $_column = $_itemColumn<int>('gaze_id')!;

    final manager = $$GazesTableTableManager(
      $_db,
      $_db.gazes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gazeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GazeSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $GazeSlotsTable> {
  $$GazeSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotKey => $composableBuilder(
    column: $table.slotKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get translateX => $composableBuilder(
    column: $table.translateX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get translateY => $composableBuilder(
    column: $table.translateY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eyeLeftX => $composableBuilder(
    column: $table.eyeLeftX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eyeLeftY => $composableBuilder(
    column: $table.eyeLeftY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eyeRightX => $composableBuilder(
    column: $table.eyeRightX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eyeRightY => $composableBuilder(
    column: $table.eyeRightY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceWidth => $composableBuilder(
    column: $table.sourceWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceHeight => $composableBuilder(
    column: $table.sourceHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GazesTableFilterComposer get gazeId {
    final $$GazesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gazeId,
      referencedTable: $db.gazes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GazesTableFilterComposer(
            $db: $db,
            $table: $db.gazes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GazeSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $GazeSlotsTable> {
  $$GazeSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotKey => $composableBuilder(
    column: $table.slotKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get translateX => $composableBuilder(
    column: $table.translateX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get translateY => $composableBuilder(
    column: $table.translateY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eyeLeftX => $composableBuilder(
    column: $table.eyeLeftX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eyeLeftY => $composableBuilder(
    column: $table.eyeLeftY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eyeRightX => $composableBuilder(
    column: $table.eyeRightX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eyeRightY => $composableBuilder(
    column: $table.eyeRightY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceWidth => $composableBuilder(
    column: $table.sourceWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceHeight => $composableBuilder(
    column: $table.sourceHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GazesTableOrderingComposer get gazeId {
    final $$GazesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gazeId,
      referencedTable: $db.gazes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GazesTableOrderingComposer(
            $db: $db,
            $table: $db.gazes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GazeSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GazeSlotsTable> {
  $$GazeSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slotKey =>
      $composableBuilder(column: $table.slotKey, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<double> get translateX => $composableBuilder(
    column: $table.translateX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get translateY => $composableBuilder(
    column: $table.translateY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<double> get eyeLeftX =>
      $composableBuilder(column: $table.eyeLeftX, builder: (column) => column);

  GeneratedColumn<double> get eyeLeftY =>
      $composableBuilder(column: $table.eyeLeftY, builder: (column) => column);

  GeneratedColumn<double> get eyeRightX =>
      $composableBuilder(column: $table.eyeRightX, builder: (column) => column);

  GeneratedColumn<double> get eyeRightY =>
      $composableBuilder(column: $table.eyeRightY, builder: (column) => column);

  GeneratedColumn<int> get sourceWidth => $composableBuilder(
    column: $table.sourceWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceHeight => $composableBuilder(
    column: $table.sourceHeight,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GazesTableAnnotationComposer get gazeId {
    final $$GazesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gazeId,
      referencedTable: $db.gazes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GazesTableAnnotationComposer(
            $db: $db,
            $table: $db.gazes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GazeSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GazeSlotsTable,
          GazeSlot,
          $$GazeSlotsTableFilterComposer,
          $$GazeSlotsTableOrderingComposer,
          $$GazeSlotsTableAnnotationComposer,
          $$GazeSlotsTableCreateCompanionBuilder,
          $$GazeSlotsTableUpdateCompanionBuilder,
          (GazeSlot, $$GazeSlotsTableReferences),
          GazeSlot,
          PrefetchHooks Function({bool gazeId})
        > {
  $$GazeSlotsTableTableManager(_$AppDatabase db, $GazeSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GazeSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GazeSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GazeSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gazeId = const Value.absent(),
                Value<String> slotKey = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<double> translateX = const Value.absent(),
                Value<double> translateY = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<double?> eyeLeftX = const Value.absent(),
                Value<double?> eyeLeftY = const Value.absent(),
                Value<double?> eyeRightX = const Value.absent(),
                Value<double?> eyeRightY = const Value.absent(),
                Value<int> sourceWidth = const Value.absent(),
                Value<int> sourceHeight = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GazeSlotsCompanion(
                id: id,
                gazeId: gazeId,
                slotKey: slotKey,
                imagePath: imagePath,
                translateX: translateX,
                translateY: translateY,
                scale: scale,
                rotation: rotation,
                eyeLeftX: eyeLeftX,
                eyeLeftY: eyeLeftY,
                eyeRightX: eyeRightX,
                eyeRightY: eyeRightY,
                sourceWidth: sourceWidth,
                sourceHeight: sourceHeight,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gazeId,
                required String slotKey,
                required String imagePath,
                Value<double> translateX = const Value.absent(),
                Value<double> translateY = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<double?> eyeLeftX = const Value.absent(),
                Value<double?> eyeLeftY = const Value.absent(),
                Value<double?> eyeRightX = const Value.absent(),
                Value<double?> eyeRightY = const Value.absent(),
                required int sourceWidth,
                required int sourceHeight,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GazeSlotsCompanion.insert(
                id: id,
                gazeId: gazeId,
                slotKey: slotKey,
                imagePath: imagePath,
                translateX: translateX,
                translateY: translateY,
                scale: scale,
                rotation: rotation,
                eyeLeftX: eyeLeftX,
                eyeLeftY: eyeLeftY,
                eyeRightX: eyeRightX,
                eyeRightY: eyeRightY,
                sourceWidth: sourceWidth,
                sourceHeight: sourceHeight,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GazeSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gazeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gazeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gazeId,
                                referencedTable: $$GazeSlotsTableReferences
                                    ._gazeIdTable(db),
                                referencedColumn: $$GazeSlotsTableReferences
                                    ._gazeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GazeSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GazeSlotsTable,
      GazeSlot,
      $$GazeSlotsTableFilterComposer,
      $$GazeSlotsTableOrderingComposer,
      $$GazeSlotsTableAnnotationComposer,
      $$GazeSlotsTableCreateCompanionBuilder,
      $$GazeSlotsTableUpdateCompanionBuilder,
      (GazeSlot, $$GazeSlotsTableReferences),
      GazeSlot,
      PrefetchHooks Function({bool gazeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GazesTableTableManager get gazes =>
      $$GazesTableTableManager(_db, _db.gazes);
  $$GazeSlotsTableTableManager get gazeSlots =>
      $$GazeSlotsTableTableManager(_db, _db.gazeSlots);
}
