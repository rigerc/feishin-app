// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeEvent);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $HomeEventCopyWith<$Res>  {
$HomeEventCopyWith(HomeEvent _, $Res Function(HomeEvent) __);
}


/// Adds pattern-matching-related methods to [HomeEvent].
extension HomeEventPatterns on HomeEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HomeStarted value)?  started,TResult Function( HomeUpdated value)?  updated,TResult Function( HomeNavigated value)?  navigate,TResult Function( HomePreferencesChanged value)?  preferences,TResult Function( HomeProfileEdited value)?  editProfile,TResult Function( HomeProfileSelected value)?  selectProfile,TResult Function( HomeProfileRemoved value)?  removeProfile,TResult Function( HomeDisconnected value)?  disconnect,TResult Function( HomeReconnected value)?  reconnect,TResult Function( HomeLifecycleChanged value)?  lifecycle,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HomeStarted() when started != null:
return started(_that);case HomeUpdated() when updated != null:
return updated(_that);case HomeNavigated() when navigate != null:
return navigate(_that);case HomePreferencesChanged() when preferences != null:
return preferences(_that);case HomeProfileEdited() when editProfile != null:
return editProfile(_that);case HomeProfileSelected() when selectProfile != null:
return selectProfile(_that);case HomeProfileRemoved() when removeProfile != null:
return removeProfile(_that);case HomeDisconnected() when disconnect != null:
return disconnect(_that);case HomeReconnected() when reconnect != null:
return reconnect(_that);case HomeLifecycleChanged() when lifecycle != null:
return lifecycle(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HomeStarted value)  started,required TResult Function( HomeUpdated value)  updated,required TResult Function( HomeNavigated value)  navigate,required TResult Function( HomePreferencesChanged value)  preferences,required TResult Function( HomeProfileEdited value)  editProfile,required TResult Function( HomeProfileSelected value)  selectProfile,required TResult Function( HomeProfileRemoved value)  removeProfile,required TResult Function( HomeDisconnected value)  disconnect,required TResult Function( HomeReconnected value)  reconnect,required TResult Function( HomeLifecycleChanged value)  lifecycle,}){
final _that = this;
switch (_that) {
case HomeStarted():
return started(_that);case HomeUpdated():
return updated(_that);case HomeNavigated():
return navigate(_that);case HomePreferencesChanged():
return preferences(_that);case HomeProfileEdited():
return editProfile(_that);case HomeProfileSelected():
return selectProfile(_that);case HomeProfileRemoved():
return removeProfile(_that);case HomeDisconnected():
return disconnect(_that);case HomeReconnected():
return reconnect(_that);case HomeLifecycleChanged():
return lifecycle(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HomeStarted value)?  started,TResult? Function( HomeUpdated value)?  updated,TResult? Function( HomeNavigated value)?  navigate,TResult? Function( HomePreferencesChanged value)?  preferences,TResult? Function( HomeProfileEdited value)?  editProfile,TResult? Function( HomeProfileSelected value)?  selectProfile,TResult? Function( HomeProfileRemoved value)?  removeProfile,TResult? Function( HomeDisconnected value)?  disconnect,TResult? Function( HomeReconnected value)?  reconnect,TResult? Function( HomeLifecycleChanged value)?  lifecycle,}){
final _that = this;
switch (_that) {
case HomeStarted() when started != null:
return started(_that);case HomeUpdated() when updated != null:
return updated(_that);case HomeNavigated() when navigate != null:
return navigate(_that);case HomePreferencesChanged() when preferences != null:
return preferences(_that);case HomeProfileEdited() when editProfile != null:
return editProfile(_that);case HomeProfileSelected() when selectProfile != null:
return selectProfile(_that);case HomeProfileRemoved() when removeProfile != null:
return removeProfile(_that);case HomeDisconnected() when disconnect != null:
return disconnect(_that);case HomeReconnected() when reconnect != null:
return reconnect(_that);case HomeLifecycleChanged() when lifecycle != null:
return lifecycle(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( SessionState session)?  updated,TResult Function( Destination destination)?  navigate,TResult Function( RemotePreferences preferences)?  preferences,TResult Function( RemoteProfile profile,  String password)?  editProfile,TResult Function( RemoteProfile profile)?  selectProfile,TResult Function( String id)?  removeProfile,TResult Function()?  disconnect,TResult Function()?  reconnect,TResult Function( bool foreground)?  lifecycle,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HomeStarted() when started != null:
return started();case HomeUpdated() when updated != null:
return updated(_that.session);case HomeNavigated() when navigate != null:
return navigate(_that.destination);case HomePreferencesChanged() when preferences != null:
return preferences(_that.preferences);case HomeProfileEdited() when editProfile != null:
return editProfile(_that.profile,_that.password);case HomeProfileSelected() when selectProfile != null:
return selectProfile(_that.profile);case HomeProfileRemoved() when removeProfile != null:
return removeProfile(_that.id);case HomeDisconnected() when disconnect != null:
return disconnect();case HomeReconnected() when reconnect != null:
return reconnect();case HomeLifecycleChanged() when lifecycle != null:
return lifecycle(_that.foreground);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( SessionState session)  updated,required TResult Function( Destination destination)  navigate,required TResult Function( RemotePreferences preferences)  preferences,required TResult Function( RemoteProfile profile,  String password)  editProfile,required TResult Function( RemoteProfile profile)  selectProfile,required TResult Function( String id)  removeProfile,required TResult Function()  disconnect,required TResult Function()  reconnect,required TResult Function( bool foreground)  lifecycle,}) {final _that = this;
switch (_that) {
case HomeStarted():
return started();case HomeUpdated():
return updated(_that.session);case HomeNavigated():
return navigate(_that.destination);case HomePreferencesChanged():
return preferences(_that.preferences);case HomeProfileEdited():
return editProfile(_that.profile,_that.password);case HomeProfileSelected():
return selectProfile(_that.profile);case HomeProfileRemoved():
return removeProfile(_that.id);case HomeDisconnected():
return disconnect();case HomeReconnected():
return reconnect();case HomeLifecycleChanged():
return lifecycle(_that.foreground);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( SessionState session)?  updated,TResult? Function( Destination destination)?  navigate,TResult? Function( RemotePreferences preferences)?  preferences,TResult? Function( RemoteProfile profile,  String password)?  editProfile,TResult? Function( RemoteProfile profile)?  selectProfile,TResult? Function( String id)?  removeProfile,TResult? Function()?  disconnect,TResult? Function()?  reconnect,TResult? Function( bool foreground)?  lifecycle,}) {final _that = this;
switch (_that) {
case HomeStarted() when started != null:
return started();case HomeUpdated() when updated != null:
return updated(_that.session);case HomeNavigated() when navigate != null:
return navigate(_that.destination);case HomePreferencesChanged() when preferences != null:
return preferences(_that.preferences);case HomeProfileEdited() when editProfile != null:
return editProfile(_that.profile,_that.password);case HomeProfileSelected() when selectProfile != null:
return selectProfile(_that.profile);case HomeProfileRemoved() when removeProfile != null:
return removeProfile(_that.id);case HomeDisconnected() when disconnect != null:
return disconnect();case HomeReconnected() when reconnect != null:
return reconnect();case HomeLifecycleChanged() when lifecycle != null:
return lifecycle(_that.foreground);case _:
  return null;

}
}

}

/// @nodoc


class HomeStarted implements HomeEvent {
  const HomeStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeStarted);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class HomeUpdated implements HomeEvent {
  const HomeUpdated(this.session);
  

 final  SessionState session;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeUpdatedCopyWith<HomeUpdated> get copyWith => _$HomeUpdatedCopyWithImpl<HomeUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeUpdated&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);



}

/// @nodoc
abstract mixin class $HomeUpdatedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeUpdatedCopyWith(HomeUpdated value, $Res Function(HomeUpdated) _then) = _$HomeUpdatedCopyWithImpl;
@useResult
$Res call({
 SessionState session
});




}
/// @nodoc
class _$HomeUpdatedCopyWithImpl<$Res>
    implements $HomeUpdatedCopyWith<$Res> {
  _$HomeUpdatedCopyWithImpl(this._self, this._then);

  final HomeUpdated _self;
  final $Res Function(HomeUpdated) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(HomeUpdated(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionState,
  ));
}


}

/// @nodoc


class HomeNavigated implements HomeEvent {
  const HomeNavigated(this.destination);
  

 final  Destination destination;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeNavigatedCopyWith<HomeNavigated> get copyWith => _$HomeNavigatedCopyWithImpl<HomeNavigated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeNavigated&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode => Object.hash(runtimeType,destination);



}

/// @nodoc
abstract mixin class $HomeNavigatedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeNavigatedCopyWith(HomeNavigated value, $Res Function(HomeNavigated) _then) = _$HomeNavigatedCopyWithImpl;
@useResult
$Res call({
 Destination destination
});




}
/// @nodoc
class _$HomeNavigatedCopyWithImpl<$Res>
    implements $HomeNavigatedCopyWith<$Res> {
  _$HomeNavigatedCopyWithImpl(this._self, this._then);

  final HomeNavigated _self;
  final $Res Function(HomeNavigated) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? destination = null,}) {
  return _then(HomeNavigated(
null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as Destination,
  ));
}


}

/// @nodoc


class HomePreferencesChanged implements HomeEvent {
  const HomePreferencesChanged(this.preferences);
  

 final  RemotePreferences preferences;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomePreferencesChangedCopyWith<HomePreferencesChanged> get copyWith => _$HomePreferencesChangedCopyWithImpl<HomePreferencesChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomePreferencesChanged&&(identical(other.preferences, preferences) || other.preferences == preferences));
}


@override
int get hashCode => Object.hash(runtimeType,preferences);



}

/// @nodoc
abstract mixin class $HomePreferencesChangedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomePreferencesChangedCopyWith(HomePreferencesChanged value, $Res Function(HomePreferencesChanged) _then) = _$HomePreferencesChangedCopyWithImpl;
@useResult
$Res call({
 RemotePreferences preferences
});




}
/// @nodoc
class _$HomePreferencesChangedCopyWithImpl<$Res>
    implements $HomePreferencesChangedCopyWith<$Res> {
  _$HomePreferencesChangedCopyWithImpl(this._self, this._then);

  final HomePreferencesChanged _self;
  final $Res Function(HomePreferencesChanged) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preferences = null,}) {
  return _then(HomePreferencesChanged(
null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as RemotePreferences,
  ));
}


}

/// @nodoc


class HomeProfileEdited implements HomeEvent {
  const HomeProfileEdited(this.profile, this.password);
  

 final  RemoteProfile profile;
 final  String password;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeProfileEditedCopyWith<HomeProfileEdited> get copyWith => _$HomeProfileEditedCopyWithImpl<HomeProfileEdited>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeProfileEdited&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,profile,password);



}

/// @nodoc
abstract mixin class $HomeProfileEditedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeProfileEditedCopyWith(HomeProfileEdited value, $Res Function(HomeProfileEdited) _then) = _$HomeProfileEditedCopyWithImpl;
@useResult
$Res call({
 RemoteProfile profile, String password
});




}
/// @nodoc
class _$HomeProfileEditedCopyWithImpl<$Res>
    implements $HomeProfileEditedCopyWith<$Res> {
  _$HomeProfileEditedCopyWithImpl(this._self, this._then);

  final HomeProfileEdited _self;
  final $Res Function(HomeProfileEdited) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = null,Object? password = null,}) {
  return _then(HomeProfileEdited(
null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as RemoteProfile,null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class HomeProfileSelected implements HomeEvent {
  const HomeProfileSelected(this.profile);
  

 final  RemoteProfile profile;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeProfileSelectedCopyWith<HomeProfileSelected> get copyWith => _$HomeProfileSelectedCopyWithImpl<HomeProfileSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeProfileSelected&&(identical(other.profile, profile) || other.profile == profile));
}


@override
int get hashCode => Object.hash(runtimeType,profile);



}

/// @nodoc
abstract mixin class $HomeProfileSelectedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeProfileSelectedCopyWith(HomeProfileSelected value, $Res Function(HomeProfileSelected) _then) = _$HomeProfileSelectedCopyWithImpl;
@useResult
$Res call({
 RemoteProfile profile
});




}
/// @nodoc
class _$HomeProfileSelectedCopyWithImpl<$Res>
    implements $HomeProfileSelectedCopyWith<$Res> {
  _$HomeProfileSelectedCopyWithImpl(this._self, this._then);

  final HomeProfileSelected _self;
  final $Res Function(HomeProfileSelected) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = null,}) {
  return _then(HomeProfileSelected(
null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as RemoteProfile,
  ));
}


}

/// @nodoc


class HomeProfileRemoved implements HomeEvent {
  const HomeProfileRemoved(this.id);
  

 final  String id;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeProfileRemovedCopyWith<HomeProfileRemoved> get copyWith => _$HomeProfileRemovedCopyWithImpl<HomeProfileRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeProfileRemoved&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);



}

/// @nodoc
abstract mixin class $HomeProfileRemovedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeProfileRemovedCopyWith(HomeProfileRemoved value, $Res Function(HomeProfileRemoved) _then) = _$HomeProfileRemovedCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$HomeProfileRemovedCopyWithImpl<$Res>
    implements $HomeProfileRemovedCopyWith<$Res> {
  _$HomeProfileRemovedCopyWithImpl(this._self, this._then);

  final HomeProfileRemoved _self;
  final $Res Function(HomeProfileRemoved) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(HomeProfileRemoved(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class HomeDisconnected implements HomeEvent {
  const HomeDisconnected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeDisconnected);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class HomeReconnected implements HomeEvent {
  const HomeReconnected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeReconnected);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class HomeLifecycleChanged implements HomeEvent {
  const HomeLifecycleChanged(this.foreground);
  

 final  bool foreground;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeLifecycleChangedCopyWith<HomeLifecycleChanged> get copyWith => _$HomeLifecycleChangedCopyWithImpl<HomeLifecycleChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeLifecycleChanged&&(identical(other.foreground, foreground) || other.foreground == foreground));
}


@override
int get hashCode => Object.hash(runtimeType,foreground);



}

/// @nodoc
abstract mixin class $HomeLifecycleChangedCopyWith<$Res> implements $HomeEventCopyWith<$Res> {
  factory $HomeLifecycleChangedCopyWith(HomeLifecycleChanged value, $Res Function(HomeLifecycleChanged) _then) = _$HomeLifecycleChangedCopyWithImpl;
@useResult
$Res call({
 bool foreground
});




}
/// @nodoc
class _$HomeLifecycleChangedCopyWithImpl<$Res>
    implements $HomeLifecycleChangedCopyWith<$Res> {
  _$HomeLifecycleChangedCopyWithImpl(this._self, this._then);

  final HomeLifecycleChanged _self;
  final $Res Function(HomeLifecycleChanged) _then;

/// Create a copy of HomeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? foreground = null,}) {
  return _then(HomeLifecycleChanged(
null == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$HomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState()';
}


}

/// @nodoc
class $HomeStateCopyWith<$Res>  {
$HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HomeLoading value)?  loading,TResult Function( HomeReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HomeLoading value)  loading,required TResult Function( HomeReady value)  ready,}){
final _that = this;
switch (_that) {
case HomeLoading():
return loading(_that);case HomeReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HomeLoading value)?  loading,TResult? Function( HomeReady value)?  ready,}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( SessionState session,  RemotePreferences preferences,  Destination destination,  List<RemoteProfile> profiles,  String? activeProfile,  String? message,  bool saving)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeReady() when ready != null:
return ready(_that.session,_that.preferences,_that.destination,_that.profiles,_that.activeProfile,_that.message,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( SessionState session,  RemotePreferences preferences,  Destination destination,  List<RemoteProfile> profiles,  String? activeProfile,  String? message,  bool saving)  ready,}) {final _that = this;
switch (_that) {
case HomeLoading():
return loading();case HomeReady():
return ready(_that.session,_that.preferences,_that.destination,_that.profiles,_that.activeProfile,_that.message,_that.saving);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( SessionState session,  RemotePreferences preferences,  Destination destination,  List<RemoteProfile> profiles,  String? activeProfile,  String? message,  bool saving)?  ready,}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeReady() when ready != null:
return ready(_that.session,_that.preferences,_that.destination,_that.profiles,_that.activeProfile,_that.message,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class HomeLoading implements HomeState {
  const HomeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.loading()';
}


}




/// @nodoc


class HomeReady implements HomeState {
  const HomeReady({required this.session, required this.preferences, required this.destination, required final  List<RemoteProfile> profiles, this.activeProfile, this.message, this.saving = false}): _profiles = profiles;
  

 final  SessionState session;
 final  RemotePreferences preferences;
 final  Destination destination;
 final  List<RemoteProfile> _profiles;
 List<RemoteProfile> get profiles {
  if (_profiles is EqualUnmodifiableListView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_profiles);
}

 final  String? activeProfile;
 final  String? message;
@JsonKey() final  bool saving;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeReadyCopyWith<HomeReady> get copyWith => _$HomeReadyCopyWithImpl<HomeReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeReady&&(identical(other.session, session) || other.session == session)&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.destination, destination) || other.destination == destination)&&const DeepCollectionEquality().equals(other._profiles, _profiles)&&(identical(other.activeProfile, activeProfile) || other.activeProfile == activeProfile)&&(identical(other.message, message) || other.message == message)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,session,preferences,destination,const DeepCollectionEquality().hash(_profiles),activeProfile,message,saving);

@override
String toString() {
  return 'HomeState.ready(session: $session, preferences: $preferences, destination: $destination, profiles: $profiles, activeProfile: $activeProfile, message: $message, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $HomeReadyCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory $HomeReadyCopyWith(HomeReady value, $Res Function(HomeReady) _then) = _$HomeReadyCopyWithImpl;
@useResult
$Res call({
 SessionState session, RemotePreferences preferences, Destination destination, List<RemoteProfile> profiles, String? activeProfile, String? message, bool saving
});




}
/// @nodoc
class _$HomeReadyCopyWithImpl<$Res>
    implements $HomeReadyCopyWith<$Res> {
  _$HomeReadyCopyWithImpl(this._self, this._then);

  final HomeReady _self;
  final $Res Function(HomeReady) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? preferences = null,Object? destination = null,Object? profiles = null,Object? activeProfile = freezed,Object? message = freezed,Object? saving = null,}) {
  return _then(HomeReady(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionState,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as RemotePreferences,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as Destination,profiles: null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<RemoteProfile>,activeProfile: freezed == activeProfile ? _self.activeProfile : activeProfile // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
