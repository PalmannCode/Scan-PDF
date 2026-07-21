// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanSettings {

/// 'system' | 'light' | 'dark'
 String get themeMode; LibraryViewMode get viewMode; LibrarySortMode get sortMode; ScanFilter get defaultFilter; CameraMode get defaultCameraMode; bool get autoOcrAfterScan; bool get flashAuto;/// JPEG quality for saved page images and PDF embedding (60–95).
 int get imageQuality;
/// Create a copy of ScanSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanSettingsCopyWith<ScanSettings> get copyWith => _$ScanSettingsCopyWithImpl<ScanSettings>(this as ScanSettings, _$identity);

  /// Serializes this ScanSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortMode, sortMode) || other.sortMode == sortMode)&&(identical(other.defaultFilter, defaultFilter) || other.defaultFilter == defaultFilter)&&(identical(other.defaultCameraMode, defaultCameraMode) || other.defaultCameraMode == defaultCameraMode)&&(identical(other.autoOcrAfterScan, autoOcrAfterScan) || other.autoOcrAfterScan == autoOcrAfterScan)&&(identical(other.flashAuto, flashAuto) || other.flashAuto == flashAuto)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeMode,viewMode,sortMode,defaultFilter,defaultCameraMode,autoOcrAfterScan,flashAuto,imageQuality);

@override
String toString() {
  return 'ScanSettings(themeMode: $themeMode, viewMode: $viewMode, sortMode: $sortMode, defaultFilter: $defaultFilter, defaultCameraMode: $defaultCameraMode, autoOcrAfterScan: $autoOcrAfterScan, flashAuto: $flashAuto, imageQuality: $imageQuality)';
}


}

/// @nodoc
abstract mixin class $ScanSettingsCopyWith<$Res>  {
  factory $ScanSettingsCopyWith(ScanSettings value, $Res Function(ScanSettings) _then) = _$ScanSettingsCopyWithImpl;
@useResult
$Res call({
 String themeMode, LibraryViewMode viewMode, LibrarySortMode sortMode, ScanFilter defaultFilter, CameraMode defaultCameraMode, bool autoOcrAfterScan, bool flashAuto, int imageQuality
});




}
/// @nodoc
class _$ScanSettingsCopyWithImpl<$Res>
    implements $ScanSettingsCopyWith<$Res> {
  _$ScanSettingsCopyWithImpl(this._self, this._then);

  final ScanSettings _self;
  final $Res Function(ScanSettings) _then;

/// Create a copy of ScanSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? viewMode = null,Object? sortMode = null,Object? defaultFilter = null,Object? defaultCameraMode = null,Object? autoOcrAfterScan = null,Object? flashAuto = null,Object? imageQuality = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,sortMode: null == sortMode ? _self.sortMode : sortMode // ignore: cast_nullable_to_non_nullable
as LibrarySortMode,defaultFilter: null == defaultFilter ? _self.defaultFilter : defaultFilter // ignore: cast_nullable_to_non_nullable
as ScanFilter,defaultCameraMode: null == defaultCameraMode ? _self.defaultCameraMode : defaultCameraMode // ignore: cast_nullable_to_non_nullable
as CameraMode,autoOcrAfterScan: null == autoOcrAfterScan ? _self.autoOcrAfterScan : autoOcrAfterScan // ignore: cast_nullable_to_non_nullable
as bool,flashAuto: null == flashAuto ? _self.flashAuto : flashAuto // ignore: cast_nullable_to_non_nullable
as bool,imageQuality: null == imageQuality ? _self.imageQuality : imageQuality // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanSettings].
extension ScanSettingsPatterns on ScanSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanSettings value)  $default,){
final _that = this;
switch (_that) {
case _ScanSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  int imageQuality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.imageQuality);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  int imageQuality)  $default,) {final _that = this;
switch (_that) {
case _ScanSettings():
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.imageQuality);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  int imageQuality)?  $default,) {final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.imageQuality);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanSettings implements ScanSettings {
  const _ScanSettings({this.themeMode = 'system', this.viewMode = LibraryViewMode.grid, this.sortMode = LibrarySortMode.dateCreated, this.defaultFilter = ScanFilter.autoColor, this.defaultCameraMode = CameraMode.document, this.autoOcrAfterScan = true, this.flashAuto = true, this.imageQuality = 85});
  factory _ScanSettings.fromJson(Map<String, dynamic> json) => _$ScanSettingsFromJson(json);

/// 'system' | 'light' | 'dark'
@override@JsonKey() final  String themeMode;
@override@JsonKey() final  LibraryViewMode viewMode;
@override@JsonKey() final  LibrarySortMode sortMode;
@override@JsonKey() final  ScanFilter defaultFilter;
@override@JsonKey() final  CameraMode defaultCameraMode;
@override@JsonKey() final  bool autoOcrAfterScan;
@override@JsonKey() final  bool flashAuto;
/// JPEG quality for saved page images and PDF embedding (60–95).
@override@JsonKey() final  int imageQuality;

/// Create a copy of ScanSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanSettingsCopyWith<_ScanSettings> get copyWith => __$ScanSettingsCopyWithImpl<_ScanSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortMode, sortMode) || other.sortMode == sortMode)&&(identical(other.defaultFilter, defaultFilter) || other.defaultFilter == defaultFilter)&&(identical(other.defaultCameraMode, defaultCameraMode) || other.defaultCameraMode == defaultCameraMode)&&(identical(other.autoOcrAfterScan, autoOcrAfterScan) || other.autoOcrAfterScan == autoOcrAfterScan)&&(identical(other.flashAuto, flashAuto) || other.flashAuto == flashAuto)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeMode,viewMode,sortMode,defaultFilter,defaultCameraMode,autoOcrAfterScan,flashAuto,imageQuality);

@override
String toString() {
  return 'ScanSettings(themeMode: $themeMode, viewMode: $viewMode, sortMode: $sortMode, defaultFilter: $defaultFilter, defaultCameraMode: $defaultCameraMode, autoOcrAfterScan: $autoOcrAfterScan, flashAuto: $flashAuto, imageQuality: $imageQuality)';
}


}

/// @nodoc
abstract mixin class _$ScanSettingsCopyWith<$Res> implements $ScanSettingsCopyWith<$Res> {
  factory _$ScanSettingsCopyWith(_ScanSettings value, $Res Function(_ScanSettings) _then) = __$ScanSettingsCopyWithImpl;
@override @useResult
$Res call({
 String themeMode, LibraryViewMode viewMode, LibrarySortMode sortMode, ScanFilter defaultFilter, CameraMode defaultCameraMode, bool autoOcrAfterScan, bool flashAuto, int imageQuality
});




}
/// @nodoc
class __$ScanSettingsCopyWithImpl<$Res>
    implements _$ScanSettingsCopyWith<$Res> {
  __$ScanSettingsCopyWithImpl(this._self, this._then);

  final _ScanSettings _self;
  final $Res Function(_ScanSettings) _then;

/// Create a copy of ScanSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? viewMode = null,Object? sortMode = null,Object? defaultFilter = null,Object? defaultCameraMode = null,Object? autoOcrAfterScan = null,Object? flashAuto = null,Object? imageQuality = null,}) {
  return _then(_ScanSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,sortMode: null == sortMode ? _self.sortMode : sortMode // ignore: cast_nullable_to_non_nullable
as LibrarySortMode,defaultFilter: null == defaultFilter ? _self.defaultFilter : defaultFilter // ignore: cast_nullable_to_non_nullable
as ScanFilter,defaultCameraMode: null == defaultCameraMode ? _self.defaultCameraMode : defaultCameraMode // ignore: cast_nullable_to_non_nullable
as CameraMode,autoOcrAfterScan: null == autoOcrAfterScan ? _self.autoOcrAfterScan : autoOcrAfterScan // ignore: cast_nullable_to_non_nullable
as bool,flashAuto: null == flashAuto ? _self.flashAuto : flashAuto // ignore: cast_nullable_to_non_nullable
as bool,imageQuality: null == imageQuality ? _self.imageQuality : imageQuality // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
