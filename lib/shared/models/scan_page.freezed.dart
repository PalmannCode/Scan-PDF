// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanPage {

 String get id; ScanFilter get filter; String get ocrText;
/// Create a copy of ScanPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanPageCopyWith<ScanPage> get copyWith => _$ScanPageCopyWithImpl<ScanPage>(this as ScanPage, _$identity);

  /// Serializes this ScanPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanPage&&(identical(other.id, id) || other.id == id)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.ocrText, ocrText) || other.ocrText == ocrText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filter,ocrText);

@override
String toString() {
  return 'ScanPage(id: $id, filter: $filter, ocrText: $ocrText)';
}


}

/// @nodoc
abstract mixin class $ScanPageCopyWith<$Res>  {
  factory $ScanPageCopyWith(ScanPage value, $Res Function(ScanPage) _then) = _$ScanPageCopyWithImpl;
@useResult
$Res call({
 String id, ScanFilter filter, String ocrText
});




}
/// @nodoc
class _$ScanPageCopyWithImpl<$Res>
    implements $ScanPageCopyWith<$Res> {
  _$ScanPageCopyWithImpl(this._self, this._then);

  final ScanPage _self;
  final $Res Function(ScanPage) _then;

/// Create a copy of ScanPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filter = null,Object? ocrText = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as ScanFilter,ocrText: null == ocrText ? _self.ocrText : ocrText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanPage].
extension ScanPagePatterns on ScanPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanPage value)  $default,){
final _that = this;
switch (_that) {
case _ScanPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanPage value)?  $default,){
final _that = this;
switch (_that) {
case _ScanPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ScanFilter filter,  String ocrText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanPage() when $default != null:
return $default(_that.id,_that.filter,_that.ocrText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ScanFilter filter,  String ocrText)  $default,) {final _that = this;
switch (_that) {
case _ScanPage():
return $default(_that.id,_that.filter,_that.ocrText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ScanFilter filter,  String ocrText)?  $default,) {final _that = this;
switch (_that) {
case _ScanPage() when $default != null:
return $default(_that.id,_that.filter,_that.ocrText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanPage extends ScanPage {
  const _ScanPage({required this.id, this.filter = ScanFilter.autoColor, this.ocrText = ''}): super._();
  factory _ScanPage.fromJson(Map<String, dynamic> json) => _$ScanPageFromJson(json);

@override final  String id;
@override@JsonKey() final  ScanFilter filter;
@override@JsonKey() final  String ocrText;

/// Create a copy of ScanPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanPageCopyWith<_ScanPage> get copyWith => __$ScanPageCopyWithImpl<_ScanPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanPage&&(identical(other.id, id) || other.id == id)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.ocrText, ocrText) || other.ocrText == ocrText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filter,ocrText);

@override
String toString() {
  return 'ScanPage(id: $id, filter: $filter, ocrText: $ocrText)';
}


}

/// @nodoc
abstract mixin class _$ScanPageCopyWith<$Res> implements $ScanPageCopyWith<$Res> {
  factory _$ScanPageCopyWith(_ScanPage value, $Res Function(_ScanPage) _then) = __$ScanPageCopyWithImpl;
@override @useResult
$Res call({
 String id, ScanFilter filter, String ocrText
});




}
/// @nodoc
class __$ScanPageCopyWithImpl<$Res>
    implements _$ScanPageCopyWith<$Res> {
  __$ScanPageCopyWithImpl(this._self, this._then);

  final _ScanPage _self;
  final $Res Function(_ScanPage) _then;

/// Create a copy of ScanPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? filter = null,Object? ocrText = null,}) {
  return _then(_ScanPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as ScanFilter,ocrText: null == ocrText ? _self.ocrText : ocrText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
