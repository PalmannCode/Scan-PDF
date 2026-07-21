// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventProgress {

 List<String> get rescuedDocIds; DateTime? get completedAt;
/// Create a copy of EventProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventProgressCopyWith<EventProgress> get copyWith => _$EventProgressCopyWithImpl<EventProgress>(this as EventProgress, _$identity);

  /// Serializes this EventProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventProgress&&const DeepCollectionEquality().equals(other.rescuedDocIds, rescuedDocIds)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rescuedDocIds),completedAt);

@override
String toString() {
  return 'EventProgress(rescuedDocIds: $rescuedDocIds, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $EventProgressCopyWith<$Res>  {
  factory $EventProgressCopyWith(EventProgress value, $Res Function(EventProgress) _then) = _$EventProgressCopyWithImpl;
@useResult
$Res call({
 List<String> rescuedDocIds, DateTime? completedAt
});




}
/// @nodoc
class _$EventProgressCopyWithImpl<$Res>
    implements $EventProgressCopyWith<$Res> {
  _$EventProgressCopyWithImpl(this._self, this._then);

  final EventProgress _self;
  final $Res Function(EventProgress) _then;

/// Create a copy of EventProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rescuedDocIds = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
rescuedDocIds: null == rescuedDocIds ? _self.rescuedDocIds : rescuedDocIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventProgress].
extension EventProgressPatterns on EventProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventProgress value)  $default,){
final _that = this;
switch (_that) {
case _EventProgress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventProgress value)?  $default,){
final _that = this;
switch (_that) {
case _EventProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> rescuedDocIds,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventProgress() when $default != null:
return $default(_that.rescuedDocIds,_that.completedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> rescuedDocIds,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _EventProgress():
return $default(_that.rescuedDocIds,_that.completedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> rescuedDocIds,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventProgress() when $default != null:
return $default(_that.rescuedDocIds,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventProgress extends EventProgress {
  const _EventProgress({final  List<String> rescuedDocIds = const <String>[], this.completedAt}): _rescuedDocIds = rescuedDocIds,super._();
  factory _EventProgress.fromJson(Map<String, dynamic> json) => _$EventProgressFromJson(json);

 final  List<String> _rescuedDocIds;
@override@JsonKey() List<String> get rescuedDocIds {
  if (_rescuedDocIds is EqualUnmodifiableListView) return _rescuedDocIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rescuedDocIds);
}

@override final  DateTime? completedAt;

/// Create a copy of EventProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventProgressCopyWith<_EventProgress> get copyWith => __$EventProgressCopyWithImpl<_EventProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventProgress&&const DeepCollectionEquality().equals(other._rescuedDocIds, _rescuedDocIds)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rescuedDocIds),completedAt);

@override
String toString() {
  return 'EventProgress(rescuedDocIds: $rescuedDocIds, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$EventProgressCopyWith<$Res> implements $EventProgressCopyWith<$Res> {
  factory _$EventProgressCopyWith(_EventProgress value, $Res Function(_EventProgress) _then) = __$EventProgressCopyWithImpl;
@override @useResult
$Res call({
 List<String> rescuedDocIds, DateTime? completedAt
});




}
/// @nodoc
class __$EventProgressCopyWithImpl<$Res>
    implements _$EventProgressCopyWith<$Res> {
  __$EventProgressCopyWithImpl(this._self, this._then);

  final _EventProgress _self;
  final $Res Function(_EventProgress) _then;

/// Create a copy of EventProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rescuedDocIds = null,Object? completedAt = freezed,}) {
  return _then(_EventProgress(
rescuedDocIds: null == rescuedDocIds ? _self._rescuedDocIds : rescuedDocIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
