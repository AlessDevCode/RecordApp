// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskFilterState {

 Set<TaskStatusFilter> get estados; String? get categoria;
/// Create a copy of TaskFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskFilterStateCopyWith<TaskFilterState> get copyWith => _$TaskFilterStateCopyWithImpl<TaskFilterState>(this as TaskFilterState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TaskFilterState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskFilterState&&const DeepCollectionEquality().equals(other.estados, _this.estados)&&(identical(other.categoria, _this.categoria) || other.categoria == _this.categoria));
}


@override
int get hashCode {
  final _this = this as TaskFilterState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.estados),_this.categoria);
}

@override
String toString() {
  final _this = this as TaskFilterState;
  return 'TaskFilterState(estados: ${_this.estados}, categoria: ${_this.categoria})';
}


}

/// @nodoc
abstract mixin class $TaskFilterStateCopyWith<$Res>  {
  factory $TaskFilterStateCopyWith(TaskFilterState value, $Res Function(TaskFilterState) _then) = _$TaskFilterStateCopyWithImpl;
@useResult
$Res call({
 Set<TaskStatusFilter> estados, String? categoria
});




}
/// @nodoc
class _$TaskFilterStateCopyWithImpl<$Res>
    implements $TaskFilterStateCopyWith<$Res> {
  _$TaskFilterStateCopyWithImpl(this._self, this._then);

  final TaskFilterState _self;
  final $Res Function(TaskFilterState) _then;

/// Create a copy of TaskFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? estados = null,Object? categoria = freezed,}) {
  return _then(TaskFilterState(
estados: null == estados ? _self.estados : estados // ignore: cast_nullable_to_non_nullable
as Set<TaskStatusFilter>,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskFilterState].
extension TaskFilterStatePatterns on TaskFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskFilterState value)  $default,){
final _that = this;
switch (_that) {
case _TaskFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<TaskStatusFilter> estados,  String? categoria)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskFilterState() when $default != null:
return $default(_that.estados,_that.categoria);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<TaskStatusFilter> estados,  String? categoria)  $default,) {final _that = this;
switch (_that) {
case _TaskFilterState():
return $default(_that.estados,_that.categoria);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<TaskStatusFilter> estados,  String? categoria)?  $default,) {final _that = this;
switch (_that) {
case _TaskFilterState() when $default != null:
return $default(_that.estados,_that.categoria);case _:
  return null;

}
}

}

/// @nodoc


class _TaskFilterState implements TaskFilterState {
  const _TaskFilterState({ Set<TaskStatusFilter> estados = const <TaskStatusFilter>{}, this.categoria}): _estados = estados;
  

 final  Set<TaskStatusFilter> _estados;
@override@JsonKey() Set<TaskStatusFilter> get estados {
  if (_estados is EqualUnmodifiableSetView) return _estados;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_estados);
}

@override final  String? categoria;

/// Create a copy of TaskFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskFilterStateCopyWith<_TaskFilterState> get copyWith => __$TaskFilterStateCopyWithImpl<_TaskFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskFilterState&&const DeepCollectionEquality().equals(other.estados, _estados)&&(identical(other.categoria, categoria) || other.categoria == categoria));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_estados),categoria);
}

@override
String toString() {
    return 'TaskFilterState(estados: $estados, categoria: $categoria)';
}


}

/// @nodoc
abstract mixin class _$TaskFilterStateCopyWith<$Res> implements $TaskFilterStateCopyWith<$Res> {
  factory _$TaskFilterStateCopyWith(_TaskFilterState value, $Res Function(_TaskFilterState) _then) = __$TaskFilterStateCopyWithImpl;
@override @useResult
$Res call({
 Set<TaskStatusFilter> estados, String? categoria
});




}
/// @nodoc
class __$TaskFilterStateCopyWithImpl<$Res>
    implements _$TaskFilterStateCopyWith<$Res> {
  __$TaskFilterStateCopyWithImpl(this._self, this._then);

  final _TaskFilterState _self;
  final $Res Function(_TaskFilterState) _then;

/// Create a copy of TaskFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? estados = null,Object? categoria = freezed,}) {
  return _then(_TaskFilterState(
estados: null == estados ? _self._estados : estados // ignore: cast_nullable_to_non_nullable
as Set<TaskStatusFilter>,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
