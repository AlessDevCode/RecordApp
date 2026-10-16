// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 String get language;@JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark) AppThemeMode get themeMode;@JsonKey(name: 'notifications_enabled') bool get notificationsEnabled;@JsonKey(name: 'cyber_username') String get cyberUsername;@JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24) TimeFormatPref get timeFormat;@JsonKey(name: 'date_format') String get dateFormat;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.notificationsEnabled, _this.notificationsEnabled) || other.notificationsEnabled == _this.notificationsEnabled)&&(identical(other.cyberUsername, _this.cyberUsername) || other.cyberUsername == _this.cyberUsername)&&(identical(other.timeFormat, _this.timeFormat) || other.timeFormat == _this.timeFormat)&&(identical(other.dateFormat, _this.dateFormat) || other.dateFormat == _this.dateFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.language,_this.themeMode,_this.notificationsEnabled,_this.cyberUsername,_this.timeFormat,_this.dateFormat);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(language: ${_this.language}, themeMode: ${_this.themeMode}, notificationsEnabled: ${_this.notificationsEnabled}, cyberUsername: ${_this.cyberUsername}, timeFormat: ${_this.timeFormat}, dateFormat: ${_this.dateFormat})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String language,@JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark) AppThemeMode themeMode,@JsonKey(name: 'notifications_enabled') bool notificationsEnabled,@JsonKey(name: 'cyber_username') String cyberUsername,@JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24) TimeFormatPref timeFormat,@JsonKey(name: 'date_format') String dateFormat
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? themeMode = null,Object? notificationsEnabled = null,Object? cyberUsername = null,Object? timeFormat = null,Object? dateFormat = null,}) {
  return _then(AppSettings(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,cyberUsername: null == cyberUsername ? _self.cyberUsername : cyberUsername // ignore: cast_nullable_to_non_nullable
as String,timeFormat: null == timeFormat ? _self.timeFormat : timeFormat // ignore: cast_nullable_to_non_nullable
as TimeFormatPref,dateFormat: null == dateFormat ? _self.dateFormat : dateFormat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language, @JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark)  AppThemeMode themeMode, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'cyber_username')  String cyberUsername, @JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24)  TimeFormatPref timeFormat, @JsonKey(name: 'date_format')  String dateFormat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.language,_that.themeMode,_that.notificationsEnabled,_that.cyberUsername,_that.timeFormat,_that.dateFormat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language, @JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark)  AppThemeMode themeMode, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'cyber_username')  String cyberUsername, @JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24)  TimeFormatPref timeFormat, @JsonKey(name: 'date_format')  String dateFormat)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.language,_that.themeMode,_that.notificationsEnabled,_that.cyberUsername,_that.timeFormat,_that.dateFormat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language, @JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark)  AppThemeMode themeMode, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'cyber_username')  String cyberUsername, @JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24)  TimeFormatPref timeFormat, @JsonKey(name: 'date_format')  String dateFormat)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.language,_that.themeMode,_that.notificationsEnabled,_that.cyberUsername,_that.timeFormat,_that.dateFormat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({this.language = 'es', @JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark) this.themeMode = AppThemeMode.dark, @JsonKey(name: 'notifications_enabled') this.notificationsEnabled = true, @JsonKey(name: 'cyber_username') this.cyberUsername = 'ALESSANDRO', @JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24) this.timeFormat = TimeFormatPref.h24, @JsonKey(name: 'date_format') this.dateFormat = 'YYYY-MM-DD'});
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  String language;
@override@JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark) final  AppThemeMode themeMode;
@override@JsonKey(name: 'notifications_enabled') final  bool notificationsEnabled;
@override@JsonKey(name: 'cyber_username') final  String cyberUsername;
@override@JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24) final  TimeFormatPref timeFormat;
@override@JsonKey(name: 'date_format') final  String dateFormat;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.language, language) || other.language == language)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.cyberUsername, cyberUsername) || other.cyberUsername == cyberUsername)&&(identical(other.timeFormat, timeFormat) || other.timeFormat == timeFormat)&&(identical(other.dateFormat, dateFormat) || other.dateFormat == dateFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,language,themeMode,notificationsEnabled,cyberUsername,timeFormat,dateFormat);
}

@override
String toString() {
    return 'AppSettings(language: $language, themeMode: $themeMode, notificationsEnabled: $notificationsEnabled, cyberUsername: $cyberUsername, timeFormat: $timeFormat, dateFormat: $dateFormat)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String language,@JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark) AppThemeMode themeMode,@JsonKey(name: 'notifications_enabled') bool notificationsEnabled,@JsonKey(name: 'cyber_username') String cyberUsername,@JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24) TimeFormatPref timeFormat,@JsonKey(name: 'date_format') String dateFormat
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? themeMode = null,Object? notificationsEnabled = null,Object? cyberUsername = null,Object? timeFormat = null,Object? dateFormat = null,}) {
  return _then(_AppSettings(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,cyberUsername: null == cyberUsername ? _self.cyberUsername : cyberUsername // ignore: cast_nullable_to_non_nullable
as String,timeFormat: null == timeFormat ? _self.timeFormat : timeFormat // ignore: cast_nullable_to_non_nullable
as TimeFormatPref,dateFormat: null == dateFormat ? _self.dateFormat : dateFormat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
