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
 String get themeMode; LibraryViewMode get viewMode; LibrarySortMode get sortMode; ScanFilter get defaultFilter; CameraMode get defaultCameraMode; bool get autoOcrAfterScan; bool get flashAuto; bool get autoCaptureEnabled; String get ocrLanguageBundle; String get defaultExportFormat; String get defaultFileNameFormat; String get appIcon; bool get syncEnabled; bool get autoUploadEnabled; String get defaultEmailSubject; String get defaultEmailBody; String get defaultEmailSignature; String get emailAttachmentFormat; bool get includeDocumentDate; bool get diagnosticLogsEnabled; bool get createSearchablePdf;/// JPEG quality for saved page images and PDF embedding (60–95).
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortMode, sortMode) || other.sortMode == sortMode)&&(identical(other.defaultFilter, defaultFilter) || other.defaultFilter == defaultFilter)&&(identical(other.defaultCameraMode, defaultCameraMode) || other.defaultCameraMode == defaultCameraMode)&&(identical(other.autoOcrAfterScan, autoOcrAfterScan) || other.autoOcrAfterScan == autoOcrAfterScan)&&(identical(other.flashAuto, flashAuto) || other.flashAuto == flashAuto)&&(identical(other.autoCaptureEnabled, autoCaptureEnabled) || other.autoCaptureEnabled == autoCaptureEnabled)&&(identical(other.ocrLanguageBundle, ocrLanguageBundle) || other.ocrLanguageBundle == ocrLanguageBundle)&&(identical(other.defaultExportFormat, defaultExportFormat) || other.defaultExportFormat == defaultExportFormat)&&(identical(other.defaultFileNameFormat, defaultFileNameFormat) || other.defaultFileNameFormat == defaultFileNameFormat)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.syncEnabled, syncEnabled) || other.syncEnabled == syncEnabled)&&(identical(other.autoUploadEnabled, autoUploadEnabled) || other.autoUploadEnabled == autoUploadEnabled)&&(identical(other.defaultEmailSubject, defaultEmailSubject) || other.defaultEmailSubject == defaultEmailSubject)&&(identical(other.defaultEmailBody, defaultEmailBody) || other.defaultEmailBody == defaultEmailBody)&&(identical(other.defaultEmailSignature, defaultEmailSignature) || other.defaultEmailSignature == defaultEmailSignature)&&(identical(other.emailAttachmentFormat, emailAttachmentFormat) || other.emailAttachmentFormat == emailAttachmentFormat)&&(identical(other.includeDocumentDate, includeDocumentDate) || other.includeDocumentDate == includeDocumentDate)&&(identical(other.diagnosticLogsEnabled, diagnosticLogsEnabled) || other.diagnosticLogsEnabled == diagnosticLogsEnabled)&&(identical(other.createSearchablePdf, createSearchablePdf) || other.createSearchablePdf == createSearchablePdf)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,themeMode,viewMode,sortMode,defaultFilter,defaultCameraMode,autoOcrAfterScan,flashAuto,autoCaptureEnabled,ocrLanguageBundle,defaultExportFormat,defaultFileNameFormat,appIcon,syncEnabled,autoUploadEnabled,defaultEmailSubject,defaultEmailBody,defaultEmailSignature,emailAttachmentFormat,includeDocumentDate,diagnosticLogsEnabled,createSearchablePdf,imageQuality]);

@override
String toString() {
  return 'ScanSettings(themeMode: $themeMode, viewMode: $viewMode, sortMode: $sortMode, defaultFilter: $defaultFilter, defaultCameraMode: $defaultCameraMode, autoOcrAfterScan: $autoOcrAfterScan, flashAuto: $flashAuto, autoCaptureEnabled: $autoCaptureEnabled, ocrLanguageBundle: $ocrLanguageBundle, defaultExportFormat: $defaultExportFormat, defaultFileNameFormat: $defaultFileNameFormat, appIcon: $appIcon, syncEnabled: $syncEnabled, autoUploadEnabled: $autoUploadEnabled, defaultEmailSubject: $defaultEmailSubject, defaultEmailBody: $defaultEmailBody, defaultEmailSignature: $defaultEmailSignature, emailAttachmentFormat: $emailAttachmentFormat, includeDocumentDate: $includeDocumentDate, diagnosticLogsEnabled: $diagnosticLogsEnabled, createSearchablePdf: $createSearchablePdf, imageQuality: $imageQuality)';
}


}

/// @nodoc
abstract mixin class $ScanSettingsCopyWith<$Res>  {
  factory $ScanSettingsCopyWith(ScanSettings value, $Res Function(ScanSettings) _then) = _$ScanSettingsCopyWithImpl;
@useResult
$Res call({
 String themeMode, LibraryViewMode viewMode, LibrarySortMode sortMode, ScanFilter defaultFilter, CameraMode defaultCameraMode, bool autoOcrAfterScan, bool flashAuto, bool autoCaptureEnabled, String ocrLanguageBundle, String defaultExportFormat, String defaultFileNameFormat, String appIcon, bool syncEnabled, bool autoUploadEnabled, String defaultEmailSubject, String defaultEmailBody, String defaultEmailSignature, String emailAttachmentFormat, bool includeDocumentDate, bool diagnosticLogsEnabled, bool createSearchablePdf, int imageQuality
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
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? viewMode = null,Object? sortMode = null,Object? defaultFilter = null,Object? defaultCameraMode = null,Object? autoOcrAfterScan = null,Object? flashAuto = null,Object? autoCaptureEnabled = null,Object? ocrLanguageBundle = null,Object? defaultExportFormat = null,Object? defaultFileNameFormat = null,Object? appIcon = null,Object? syncEnabled = null,Object? autoUploadEnabled = null,Object? defaultEmailSubject = null,Object? defaultEmailBody = null,Object? defaultEmailSignature = null,Object? emailAttachmentFormat = null,Object? includeDocumentDate = null,Object? diagnosticLogsEnabled = null,Object? createSearchablePdf = null,Object? imageQuality = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,sortMode: null == sortMode ? _self.sortMode : sortMode // ignore: cast_nullable_to_non_nullable
as LibrarySortMode,defaultFilter: null == defaultFilter ? _self.defaultFilter : defaultFilter // ignore: cast_nullable_to_non_nullable
as ScanFilter,defaultCameraMode: null == defaultCameraMode ? _self.defaultCameraMode : defaultCameraMode // ignore: cast_nullable_to_non_nullable
as CameraMode,autoOcrAfterScan: null == autoOcrAfterScan ? _self.autoOcrAfterScan : autoOcrAfterScan // ignore: cast_nullable_to_non_nullable
as bool,flashAuto: null == flashAuto ? _self.flashAuto : flashAuto // ignore: cast_nullable_to_non_nullable
as bool,autoCaptureEnabled: null == autoCaptureEnabled ? _self.autoCaptureEnabled : autoCaptureEnabled // ignore: cast_nullable_to_non_nullable
as bool,ocrLanguageBundle: null == ocrLanguageBundle ? _self.ocrLanguageBundle : ocrLanguageBundle // ignore: cast_nullable_to_non_nullable
as String,defaultExportFormat: null == defaultExportFormat ? _self.defaultExportFormat : defaultExportFormat // ignore: cast_nullable_to_non_nullable
as String,defaultFileNameFormat: null == defaultFileNameFormat ? _self.defaultFileNameFormat : defaultFileNameFormat // ignore: cast_nullable_to_non_nullable
as String,appIcon: null == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String,syncEnabled: null == syncEnabled ? _self.syncEnabled : syncEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoUploadEnabled: null == autoUploadEnabled ? _self.autoUploadEnabled : autoUploadEnabled // ignore: cast_nullable_to_non_nullable
as bool,defaultEmailSubject: null == defaultEmailSubject ? _self.defaultEmailSubject : defaultEmailSubject // ignore: cast_nullable_to_non_nullable
as String,defaultEmailBody: null == defaultEmailBody ? _self.defaultEmailBody : defaultEmailBody // ignore: cast_nullable_to_non_nullable
as String,defaultEmailSignature: null == defaultEmailSignature ? _self.defaultEmailSignature : defaultEmailSignature // ignore: cast_nullable_to_non_nullable
as String,emailAttachmentFormat: null == emailAttachmentFormat ? _self.emailAttachmentFormat : emailAttachmentFormat // ignore: cast_nullable_to_non_nullable
as String,includeDocumentDate: null == includeDocumentDate ? _self.includeDocumentDate : includeDocumentDate // ignore: cast_nullable_to_non_nullable
as bool,diagnosticLogsEnabled: null == diagnosticLogsEnabled ? _self.diagnosticLogsEnabled : diagnosticLogsEnabled // ignore: cast_nullable_to_non_nullable
as bool,createSearchablePdf: null == createSearchablePdf ? _self.createSearchablePdf : createSearchablePdf // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  bool autoCaptureEnabled,  String ocrLanguageBundle,  String defaultExportFormat,  String defaultFileNameFormat,  String appIcon,  bool syncEnabled,  bool autoUploadEnabled,  String defaultEmailSubject,  String defaultEmailBody,  String defaultEmailSignature,  String emailAttachmentFormat,  bool includeDocumentDate,  bool diagnosticLogsEnabled,  bool createSearchablePdf,  int imageQuality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.autoCaptureEnabled,_that.ocrLanguageBundle,_that.defaultExportFormat,_that.defaultFileNameFormat,_that.appIcon,_that.syncEnabled,_that.autoUploadEnabled,_that.defaultEmailSubject,_that.defaultEmailBody,_that.defaultEmailSignature,_that.emailAttachmentFormat,_that.includeDocumentDate,_that.diagnosticLogsEnabled,_that.createSearchablePdf,_that.imageQuality);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  bool autoCaptureEnabled,  String ocrLanguageBundle,  String defaultExportFormat,  String defaultFileNameFormat,  String appIcon,  bool syncEnabled,  bool autoUploadEnabled,  String defaultEmailSubject,  String defaultEmailBody,  String defaultEmailSignature,  String emailAttachmentFormat,  bool includeDocumentDate,  bool diagnosticLogsEnabled,  bool createSearchablePdf,  int imageQuality)  $default,) {final _that = this;
switch (_that) {
case _ScanSettings():
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.autoCaptureEnabled,_that.ocrLanguageBundle,_that.defaultExportFormat,_that.defaultFileNameFormat,_that.appIcon,_that.syncEnabled,_that.autoUploadEnabled,_that.defaultEmailSubject,_that.defaultEmailBody,_that.defaultEmailSignature,_that.emailAttachmentFormat,_that.includeDocumentDate,_that.diagnosticLogsEnabled,_that.createSearchablePdf,_that.imageQuality);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeMode,  LibraryViewMode viewMode,  LibrarySortMode sortMode,  ScanFilter defaultFilter,  CameraMode defaultCameraMode,  bool autoOcrAfterScan,  bool flashAuto,  bool autoCaptureEnabled,  String ocrLanguageBundle,  String defaultExportFormat,  String defaultFileNameFormat,  String appIcon,  bool syncEnabled,  bool autoUploadEnabled,  String defaultEmailSubject,  String defaultEmailBody,  String defaultEmailSignature,  String emailAttachmentFormat,  bool includeDocumentDate,  bool diagnosticLogsEnabled,  bool createSearchablePdf,  int imageQuality)?  $default,) {final _that = this;
switch (_that) {
case _ScanSettings() when $default != null:
return $default(_that.themeMode,_that.viewMode,_that.sortMode,_that.defaultFilter,_that.defaultCameraMode,_that.autoOcrAfterScan,_that.flashAuto,_that.autoCaptureEnabled,_that.ocrLanguageBundle,_that.defaultExportFormat,_that.defaultFileNameFormat,_that.appIcon,_that.syncEnabled,_that.autoUploadEnabled,_that.defaultEmailSubject,_that.defaultEmailBody,_that.defaultEmailSignature,_that.emailAttachmentFormat,_that.includeDocumentDate,_that.diagnosticLogsEnabled,_that.createSearchablePdf,_that.imageQuality);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanSettings implements ScanSettings {
  const _ScanSettings({this.themeMode = 'system', this.viewMode = LibraryViewMode.grid, this.sortMode = LibrarySortMode.dateCreated, this.defaultFilter = ScanFilter.autoColor, this.defaultCameraMode = CameraMode.document, this.autoOcrAfterScan = true, this.flashAuto = true, this.autoCaptureEnabled = false, this.ocrLanguageBundle = 'latin', this.defaultExportFormat = 'pdf', this.defaultFileNameFormat = 'Scan yyyy-MM-dd HH.mm', this.appIcon = 'default', this.syncEnabled = false, this.autoUploadEnabled = false, this.defaultEmailSubject = 'Scanned document: {title}', this.defaultEmailBody = 'Please find {title} attached.', this.defaultEmailSignature = '', this.emailAttachmentFormat = 'pdf', this.includeDocumentDate = true, this.diagnosticLogsEnabled = false, this.createSearchablePdf = true, this.imageQuality = 85});
  factory _ScanSettings.fromJson(Map<String, dynamic> json) => _$ScanSettingsFromJson(json);

/// 'system' | 'light' | 'dark'
@override@JsonKey() final  String themeMode;
@override@JsonKey() final  LibraryViewMode viewMode;
@override@JsonKey() final  LibrarySortMode sortMode;
@override@JsonKey() final  ScanFilter defaultFilter;
@override@JsonKey() final  CameraMode defaultCameraMode;
@override@JsonKey() final  bool autoOcrAfterScan;
@override@JsonKey() final  bool flashAuto;
@override@JsonKey() final  bool autoCaptureEnabled;
@override@JsonKey() final  String ocrLanguageBundle;
@override@JsonKey() final  String defaultExportFormat;
@override@JsonKey() final  String defaultFileNameFormat;
@override@JsonKey() final  String appIcon;
@override@JsonKey() final  bool syncEnabled;
@override@JsonKey() final  bool autoUploadEnabled;
@override@JsonKey() final  String defaultEmailSubject;
@override@JsonKey() final  String defaultEmailBody;
@override@JsonKey() final  String defaultEmailSignature;
@override@JsonKey() final  String emailAttachmentFormat;
@override@JsonKey() final  bool includeDocumentDate;
@override@JsonKey() final  bool diagnosticLogsEnabled;
@override@JsonKey() final  bool createSearchablePdf;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortMode, sortMode) || other.sortMode == sortMode)&&(identical(other.defaultFilter, defaultFilter) || other.defaultFilter == defaultFilter)&&(identical(other.defaultCameraMode, defaultCameraMode) || other.defaultCameraMode == defaultCameraMode)&&(identical(other.autoOcrAfterScan, autoOcrAfterScan) || other.autoOcrAfterScan == autoOcrAfterScan)&&(identical(other.flashAuto, flashAuto) || other.flashAuto == flashAuto)&&(identical(other.autoCaptureEnabled, autoCaptureEnabled) || other.autoCaptureEnabled == autoCaptureEnabled)&&(identical(other.ocrLanguageBundle, ocrLanguageBundle) || other.ocrLanguageBundle == ocrLanguageBundle)&&(identical(other.defaultExportFormat, defaultExportFormat) || other.defaultExportFormat == defaultExportFormat)&&(identical(other.defaultFileNameFormat, defaultFileNameFormat) || other.defaultFileNameFormat == defaultFileNameFormat)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.syncEnabled, syncEnabled) || other.syncEnabled == syncEnabled)&&(identical(other.autoUploadEnabled, autoUploadEnabled) || other.autoUploadEnabled == autoUploadEnabled)&&(identical(other.defaultEmailSubject, defaultEmailSubject) || other.defaultEmailSubject == defaultEmailSubject)&&(identical(other.defaultEmailBody, defaultEmailBody) || other.defaultEmailBody == defaultEmailBody)&&(identical(other.defaultEmailSignature, defaultEmailSignature) || other.defaultEmailSignature == defaultEmailSignature)&&(identical(other.emailAttachmentFormat, emailAttachmentFormat) || other.emailAttachmentFormat == emailAttachmentFormat)&&(identical(other.includeDocumentDate, includeDocumentDate) || other.includeDocumentDate == includeDocumentDate)&&(identical(other.diagnosticLogsEnabled, diagnosticLogsEnabled) || other.diagnosticLogsEnabled == diagnosticLogsEnabled)&&(identical(other.createSearchablePdf, createSearchablePdf) || other.createSearchablePdf == createSearchablePdf)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,themeMode,viewMode,sortMode,defaultFilter,defaultCameraMode,autoOcrAfterScan,flashAuto,autoCaptureEnabled,ocrLanguageBundle,defaultExportFormat,defaultFileNameFormat,appIcon,syncEnabled,autoUploadEnabled,defaultEmailSubject,defaultEmailBody,defaultEmailSignature,emailAttachmentFormat,includeDocumentDate,diagnosticLogsEnabled,createSearchablePdf,imageQuality]);

@override
String toString() {
  return 'ScanSettings(themeMode: $themeMode, viewMode: $viewMode, sortMode: $sortMode, defaultFilter: $defaultFilter, defaultCameraMode: $defaultCameraMode, autoOcrAfterScan: $autoOcrAfterScan, flashAuto: $flashAuto, autoCaptureEnabled: $autoCaptureEnabled, ocrLanguageBundle: $ocrLanguageBundle, defaultExportFormat: $defaultExportFormat, defaultFileNameFormat: $defaultFileNameFormat, appIcon: $appIcon, syncEnabled: $syncEnabled, autoUploadEnabled: $autoUploadEnabled, defaultEmailSubject: $defaultEmailSubject, defaultEmailBody: $defaultEmailBody, defaultEmailSignature: $defaultEmailSignature, emailAttachmentFormat: $emailAttachmentFormat, includeDocumentDate: $includeDocumentDate, diagnosticLogsEnabled: $diagnosticLogsEnabled, createSearchablePdf: $createSearchablePdf, imageQuality: $imageQuality)';
}


}

/// @nodoc
abstract mixin class _$ScanSettingsCopyWith<$Res> implements $ScanSettingsCopyWith<$Res> {
  factory _$ScanSettingsCopyWith(_ScanSettings value, $Res Function(_ScanSettings) _then) = __$ScanSettingsCopyWithImpl;
@override @useResult
$Res call({
 String themeMode, LibraryViewMode viewMode, LibrarySortMode sortMode, ScanFilter defaultFilter, CameraMode defaultCameraMode, bool autoOcrAfterScan, bool flashAuto, bool autoCaptureEnabled, String ocrLanguageBundle, String defaultExportFormat, String defaultFileNameFormat, String appIcon, bool syncEnabled, bool autoUploadEnabled, String defaultEmailSubject, String defaultEmailBody, String defaultEmailSignature, String emailAttachmentFormat, bool includeDocumentDate, bool diagnosticLogsEnabled, bool createSearchablePdf, int imageQuality
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
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? viewMode = null,Object? sortMode = null,Object? defaultFilter = null,Object? defaultCameraMode = null,Object? autoOcrAfterScan = null,Object? flashAuto = null,Object? autoCaptureEnabled = null,Object? ocrLanguageBundle = null,Object? defaultExportFormat = null,Object? defaultFileNameFormat = null,Object? appIcon = null,Object? syncEnabled = null,Object? autoUploadEnabled = null,Object? defaultEmailSubject = null,Object? defaultEmailBody = null,Object? defaultEmailSignature = null,Object? emailAttachmentFormat = null,Object? includeDocumentDate = null,Object? diagnosticLogsEnabled = null,Object? createSearchablePdf = null,Object? imageQuality = null,}) {
  return _then(_ScanSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,sortMode: null == sortMode ? _self.sortMode : sortMode // ignore: cast_nullable_to_non_nullable
as LibrarySortMode,defaultFilter: null == defaultFilter ? _self.defaultFilter : defaultFilter // ignore: cast_nullable_to_non_nullable
as ScanFilter,defaultCameraMode: null == defaultCameraMode ? _self.defaultCameraMode : defaultCameraMode // ignore: cast_nullable_to_non_nullable
as CameraMode,autoOcrAfterScan: null == autoOcrAfterScan ? _self.autoOcrAfterScan : autoOcrAfterScan // ignore: cast_nullable_to_non_nullable
as bool,flashAuto: null == flashAuto ? _self.flashAuto : flashAuto // ignore: cast_nullable_to_non_nullable
as bool,autoCaptureEnabled: null == autoCaptureEnabled ? _self.autoCaptureEnabled : autoCaptureEnabled // ignore: cast_nullable_to_non_nullable
as bool,ocrLanguageBundle: null == ocrLanguageBundle ? _self.ocrLanguageBundle : ocrLanguageBundle // ignore: cast_nullable_to_non_nullable
as String,defaultExportFormat: null == defaultExportFormat ? _self.defaultExportFormat : defaultExportFormat // ignore: cast_nullable_to_non_nullable
as String,defaultFileNameFormat: null == defaultFileNameFormat ? _self.defaultFileNameFormat : defaultFileNameFormat // ignore: cast_nullable_to_non_nullable
as String,appIcon: null == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String,syncEnabled: null == syncEnabled ? _self.syncEnabled : syncEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoUploadEnabled: null == autoUploadEnabled ? _self.autoUploadEnabled : autoUploadEnabled // ignore: cast_nullable_to_non_nullable
as bool,defaultEmailSubject: null == defaultEmailSubject ? _self.defaultEmailSubject : defaultEmailSubject // ignore: cast_nullable_to_non_nullable
as String,defaultEmailBody: null == defaultEmailBody ? _self.defaultEmailBody : defaultEmailBody // ignore: cast_nullable_to_non_nullable
as String,defaultEmailSignature: null == defaultEmailSignature ? _self.defaultEmailSignature : defaultEmailSignature // ignore: cast_nullable_to_non_nullable
as String,emailAttachmentFormat: null == emailAttachmentFormat ? _self.emailAttachmentFormat : emailAttachmentFormat // ignore: cast_nullable_to_non_nullable
as String,includeDocumentDate: null == includeDocumentDate ? _self.includeDocumentDate : includeDocumentDate // ignore: cast_nullable_to_non_nullable
as bool,diagnosticLogsEnabled: null == diagnosticLogsEnabled ? _self.diagnosticLogsEnabled : diagnosticLogsEnabled // ignore: cast_nullable_to_non_nullable
as bool,createSearchablePdf: null == createSearchablePdf ? _self.createSearchablePdf : createSearchablePdf // ignore: cast_nullable_to_non_nullable
as bool,imageQuality: null == imageQuality ? _self.imageQuality : imageQuality // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
