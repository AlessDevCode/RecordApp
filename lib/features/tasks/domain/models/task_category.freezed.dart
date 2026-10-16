// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskCategory {

 String get nombre; String get emoji;
/// Create a copy of TaskCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCategoryCopyWith<TaskCategory> get copyWith => _$TaskCategoryCopyWithImpl<TaskCategory>(this as TaskCategory, _$identity);

  /// Serializes this TaskCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCategory&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskCategory;
  return Object.hash(runtimeType,_this.nombre,_this.emoji);
}

@override
String toString() {
  final _this = this as TaskCategory;
  return 'TaskCategory(nombre: ${_this.nombre}, emoji: ${_this.emoji})';
}


}

/// @nodoc
abstract mixin class $TaskCategoryCopyWith<$Res>  {
  factory $TaskCategoryCopyWith(TaskCategory value, $Res Function(TaskCategory) _then) = _$TaskCategoryCopyWithImpl;
@useResult
$Res call({
 String nombre, String emoji
});




}
/// @nodoc
class _$TaskCategoryCopyWithImpl<$Res>
    implements $TaskCategoryCopyWith<$Res> {
  _$TaskCategoryCopyWithImpl(this._self, this._then);

  final TaskCategory _self;
  final $Res Function(TaskCategory) _then;

/// Create a copy of TaskCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nombre = null,Object? emoji = null,}) {
  return _then(TaskCategory(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskCategory].
extension TaskCategoryPatterns on TaskCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskCategory value)  $default,){
final _that = this;
switch (_that) {
case _TaskCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskCategory value)?  $default,){
final _that = this;
switch (_that) {
case _TaskCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nombre,  String emoji)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskCategory() when $default != null:
return $default(_that.nombre,_that.emoji);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nombre,  String emoji)  $default,) {final _that = this;
switch (_that) {
case _TaskCategory():
return $default(_that.nombre,_that.emoji);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nombre,  String emoji)?  $default,) {final _that = this;
switch (_that) {
case _TaskCategory() when $default != null:
return $default(_that.nombre,_that.emoji);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskCategory implements TaskCategory {
  const _TaskCategory({required this.nombre, required this.emoji});
  factory _TaskCategory.fromJson(Map<String, dynamic> json) => _$TaskCategoryFromJson(json);

@override final  String nombre;
@override final  String emoji;

/// Create a copy of TaskCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCategoryCopyWith<_TaskCategory> get copyWith => __$TaskCategoryCopyWithImpl<_TaskCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskCategory&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.emoji, emoji) || other.emoji == emoji));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nombre,emoji);
}

@override
String toString() {
    return 'TaskCategory(nombre: $nombre, emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class _$TaskCategoryCopyWith<$Res> implements $TaskCategoryCopyWith<$Res> {
  factory _$TaskCategoryCopyWith(_TaskCategory value, $Res Function(_TaskCategory) _then) = __$TaskCategoryCopyWithImpl;
@override @useResult
$Res call({
 String nombre, String emoji
});




}
/// @nodoc
class __$TaskCategoryCopyWithImpl<$Res>
    implements _$TaskCategoryCopyWith<$Res> {
  __$TaskCategoryCopyWithImpl(this._self, this._then);

  final _TaskCategory _self;
  final $Res Function(_TaskCategory) _then;

/// Create a copy of TaskCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nombre = null,Object? emoji = null,}) {
  return _then(_TaskCategory(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
