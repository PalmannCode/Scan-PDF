// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanDocument {

 String get id; String get title; String? get folderId; DateTime get createdAt; DateTime get modifiedAt; List<ScanPage> get pages; bool get isDeleted; DateTime? get deletedAt;
/// Create a copy of ScanDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanDocumentCopyWith<ScanDocument> get copyWith => _$ScanDocumentCopyWithImpl<ScanDocument>(this as ScanDocument, _$identity);

  /// Serializes this ScanDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,folderId,createdAt,modifiedAt,const DeepCollectionEquality().hash(pages),isDeleted,deletedAt);

@override
String toString() {
  return 'ScanDocument(id: $id, title: $title, folderId: $folderId, createdAt: $createdAt, modifiedAt: $modifiedAt, pages: $pages, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ScanDocumentCopyWith<$Res>  {
  factory $ScanDocumentCopyWith(ScanDocument value, $Res Function(ScanDocument) _then) = _$ScanDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? folderId, DateTime createdAt, DateTime modifiedAt, List<ScanPage> pages, bool isDeleted, DateTime? deletedAt
});




}
/// @nodoc
class _$ScanDocumentCopyWithImpl<$Res>
    implements $ScanDocumentCopyWith<$Res> {
  _$ScanDocumentCopyWithImpl(this._self, this._then);

  final ScanDocument _self;
  final $Res Function(ScanDocument) _then;

/// Create a copy of ScanDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? folderId = freezed,Object? createdAt = null,Object? modifiedAt = null,Object? pages = null,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<ScanPage>,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanDocument].
extension ScanDocumentPatterns on ScanDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanDocument value)  $default,){
final _that = this;
switch (_that) {
case _ScanDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanDocument value)?  $default,){
final _that = this;
switch (_that) {
case _ScanDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? folderId,  DateTime createdAt,  DateTime modifiedAt,  List<ScanPage> pages,  bool isDeleted,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanDocument() when $default != null:
return $default(_that.id,_that.title,_that.folderId,_that.createdAt,_that.modifiedAt,_that.pages,_that.isDeleted,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? folderId,  DateTime createdAt,  DateTime modifiedAt,  List<ScanPage> pages,  bool isDeleted,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ScanDocument():
return $default(_that.id,_that.title,_that.folderId,_that.createdAt,_that.modifiedAt,_that.pages,_that.isDeleted,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? folderId,  DateTime createdAt,  DateTime modifiedAt,  List<ScanPage> pages,  bool isDeleted,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ScanDocument() when $default != null:
return $default(_that.id,_that.title,_that.folderId,_that.createdAt,_that.modifiedAt,_that.pages,_that.isDeleted,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanDocument extends ScanDocument {
  const _ScanDocument({required this.id, required this.title, this.folderId, required this.createdAt, required this.modifiedAt, final  List<ScanPage> pages = const <ScanPage>[], this.isDeleted = false, this.deletedAt}): _pages = pages,super._();
  factory _ScanDocument.fromJson(Map<String, dynamic> json) => _$ScanDocumentFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? folderId;
@override final  DateTime createdAt;
@override final  DateTime modifiedAt;
 final  List<ScanPage> _pages;
@override@JsonKey() List<ScanPage> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

@override@JsonKey() final  bool isDeleted;
@override final  DateTime? deletedAt;

/// Create a copy of ScanDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanDocumentCopyWith<_ScanDocument> get copyWith => __$ScanDocumentCopyWithImpl<_ScanDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,folderId,createdAt,modifiedAt,const DeepCollectionEquality().hash(_pages),isDeleted,deletedAt);

@override
String toString() {
  return 'ScanDocument(id: $id, title: $title, folderId: $folderId, createdAt: $createdAt, modifiedAt: $modifiedAt, pages: $pages, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ScanDocumentCopyWith<$Res> implements $ScanDocumentCopyWith<$Res> {
  factory _$ScanDocumentCopyWith(_ScanDocument value, $Res Function(_ScanDocument) _then) = __$ScanDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? folderId, DateTime createdAt, DateTime modifiedAt, List<ScanPage> pages, bool isDeleted, DateTime? deletedAt
});




}
/// @nodoc
class __$ScanDocumentCopyWithImpl<$Res>
    implements _$ScanDocumentCopyWith<$Res> {
  __$ScanDocumentCopyWithImpl(this._self, this._then);

  final _ScanDocument _self;
  final $Res Function(_ScanDocument) _then;

/// Create a copy of ScanDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? folderId = freezed,Object? createdAt = null,Object? modifiedAt = null,Object? pages = null,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_ScanDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<ScanPage>,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
