import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/remote.dart';

part 'home_bloc.freezed.dart';

@Freezed(toStringOverride: false)
sealed class HomeEvent with _$HomeEvent {
  const factory HomeEvent.started() = HomeStarted;
  const factory HomeEvent.updated(SessionState session) = HomeUpdated;
  const factory HomeEvent.navigate(Destination destination) = HomeNavigated;
  const factory HomeEvent.preferences(RemotePreferences preferences) =
      HomePreferencesChanged;
  const factory HomeEvent.editProfile(RemoteProfile profile, String password) =
      HomeProfileEdited;
  const factory HomeEvent.selectProfile(RemoteProfile profile) =
      HomeProfileSelected;
  const factory HomeEvent.removeProfile(String id) = HomeProfileRemoved;
  const factory HomeEvent.disconnect() = HomeDisconnected;
  const factory HomeEvent.reconnect() = HomeReconnected;
  const factory HomeEvent.lifecycle(bool foreground) = HomeLifecycleChanged;
}

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.ready({
    required SessionState session,
    required RemotePreferences preferences,
    required Destination destination,
    required List<RemoteProfile> profiles,
    String? activeProfile,
    String? message,
    @Default(false) bool saving,
  }) = HomeReady;
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this.repository, this.configuration)
    : super(const HomeState.loading()) {
    _subscription = repository.updates.listen(
      (session) => add(HomeEvent.updated(session)),
    );
    on<HomeStarted>(_start);
    on<HomeUpdated>((event, emit) {
      if (state case final HomeReady ready
          when event.session.generation == repository.state.generation) {
        emit(ready.copyWith(session: event.session));
      }
    });
    on<HomeNavigated>((event, emit) {
      if (state case final HomeReady ready) {
        emit(ready.copyWith(destination: event.destination));
      }
    });
    on<HomePreferencesChanged>(_preferences);
    on<HomeProfileEdited>(_save);
    on<HomeProfileSelected>(_select);
    on<HomeProfileRemoved>(_delete);
    on<HomeDisconnected>(_disconnect);
    on<HomeReconnected>((event, emit) async {
      if (state case final HomeReady ready when !ready.saving) {
        final profile = _active(ready);
        if (profile != null) await _connect(profile, emit);
      }
    });
    on<HomeLifecycleChanged>(
      (event, _) => repository.setForeground(event.foreground),
    );
  }

  final RemoteRepository repository;
  final RemoteConfiguration configuration;
  late final StreamSubscription<SessionState> _subscription;
  final _sessionPasswords = <String, String>{};
  Future<void> _preferenceWrites = Future<void>.value();

  Future<void> _start(HomeStarted event, Emitter<HomeState> emit) async {
    try {
      final preferences = await configuration.loadPreferences();
      final saved = await configuration.loadProfiles();
      final profile = saved.profiles
          .where((profile) => profile.id == saved.active)
          .firstOrNull;
      repository.setAutoReconnect(preferences.autoReconnect);
      emit(
        HomeState.ready(
          session: repository.state,
          preferences: preferences,
          destination: profile == null
              ? Destination.profiles
              : preferences.start,
          profiles: List.unmodifiable(saved.profiles),
          activeProfile: profile?.id,
        ),
      );
      if (profile != null && preferences.autoReconnect) {
        await _connect(profile, emit);
      }
    } catch (_) {
      emit(
        HomeState.ready(
          session: repository.state,
          preferences: const RemotePreferences(),
          destination: Destination.profiles,
          profiles: const [],
          message: 'Saved settings could not be read.',
        ),
      );
    }
  }

  Future<void> _preferences(
    HomePreferencesChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (state case final HomeReady ready) {
      emit(ready.copyWith(preferences: event.preferences, message: null));
      repository.setAutoReconnect(event.preferences.autoReconnect);
      final write = _preferenceWrites.then(
        (_) => configuration.savePreferences(event.preferences),
      );
      _preferenceWrites = write.catchError((Object _) {});
      try {
        await write;
      } catch (_) {
        if (state case final HomeReady current) {
          emit(current.copyWith(message: 'Settings could not be saved.'));
        }
      }
    }
  }

  Future<void> _save(HomeProfileEdited event, Emitter<HomeState> emit) async {
    final ready = state;
    if (ready is! HomeReady || ready.saving) return;
    emit(ready.copyWith(saving: true, message: null));
    try {
      await configuration.saveProfile(event.profile, event.password);
      await configuration.selectProfile(event.profile.id);
      _sessionPasswords[event.profile.id] = event.password;
      final profiles = (await configuration.loadProfiles()).profiles;
      final current = state as HomeReady;
      emit(
        current.copyWith(
          activeProfile: event.profile.id,
          profiles: List.unmodifiable(profiles),
          destination: current.preferences.start,
          saving: false,
        ),
      );
      await _connect(event.profile, emit);
    } catch (_) {
      final current = state as HomeReady;
      emit(
        current.copyWith(
          saving: false,
          message: 'The connection profile could not be saved.',
        ),
      );
    }
  }

  Future<void> _select(
    HomeProfileSelected event,
    Emitter<HomeState> emit,
  ) async {
    final ready = state;
    if (ready is! HomeReady || ready.saving) return;
    emit(ready.copyWith(saving: true, message: null));
    try {
      await configuration.selectProfile(event.profile.id);
      final current = state as HomeReady;
      emit(
        current.copyWith(
          activeProfile: event.profile.id,
          destination: current.preferences.start,
          saving: false,
        ),
      );
      await _connect(event.profile, emit);
    } catch (_) {
      final current = state as HomeReady;
      emit(
        current.copyWith(
          saving: false,
          message: 'Could not select this desktop.',
        ),
      );
    }
  }

  Future<void> _delete(
    HomeProfileRemoved event,
    Emitter<HomeState> emit,
  ) async {
    final ready = state;
    if (ready is! HomeReady || ready.saving) return;
    emit(ready.copyWith(saving: true, message: null));
    try {
      await configuration.removeProfile(event.id);
      _sessionPasswords.remove(event.id);
      final current = state as HomeReady;
      final active = current.activeProfile == event.id;
      if (active) repository.disconnect();
      emit(
        current.copyWith(
          saving: false,
          activeProfile: active ? null : current.activeProfile,
          profiles: current.profiles
              .where((profile) => profile.id != event.id)
              .toList(),
          session: repository.state,
        ),
      );
    } catch (_) {
      final current = state as HomeReady;
      emit(
        current.copyWith(
          saving: false,
          message: 'The connection profile could not be removed.',
        ),
      );
    }
  }

  Future<void> _disconnect(
    HomeDisconnected event,
    Emitter<HomeState> emit,
  ) async {
    repository.disconnect();
    if (state case final HomeReady ready) {
      emit(ready.copyWith(session: repository.state, activeProfile: null));
      try {
        await configuration.selectProfile(null);
      } catch (_) {
        if (state case final HomeReady current) {
          emit(
            current.copyWith(
              message: 'The saved connection selection could not be cleared.',
            ),
          );
        }
      }
    }
  }

  Future<void> _connect(RemoteProfile profile, Emitter<HomeState> emit) async {
    if (state case final HomeReady ready
        when ready.activeProfile == profile.id && !ready.saving) {
      repository.disconnect();
      emit(
        ready.copyWith(session: repository.state, saving: true, message: null),
      );
      try {
        final password =
            _sessionPasswords[profile.id] ??
            await configuration.passwordFor(profile);
        if (state case final HomeReady current
            when current.activeProfile == profile.id) {
          final connection = repository.connect(profile, password);
          emit(current.copyWith(saving: false, session: repository.state));
          await connection;
        } else if (state case final HomeReady current) {
          emit(current.copyWith(saving: false));
        }
      } catch (_) {
        if (state case final HomeReady current) {
          emit(
            current.copyWith(
              saving: false,
              message: 'Re-enter the password for this desktop.',
            ),
          );
        }
      }
    }
  }

  RemoteProfile? _active(HomeReady ready) => ready.profiles
      .where((profile) => profile.id == ready.activeProfile)
      .firstOrNull;

  String nextProfileId() {
    final random = Random.secure();
    return List.generate(
      4,
      (_) => random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
    ).join();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    repository.disconnect();
    await super.close();
  }
}
