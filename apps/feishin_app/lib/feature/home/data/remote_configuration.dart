import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/remote.dart';
import 'remote_protocol.dart';

class PreferenceRemoteConfiguration implements RemoteConfiguration {
  PreferenceRemoteConfiguration();

  static const _profilesKey = 'feishin.profiles';
  static const _activeKey = 'feishin.active';
  static const _preferencesKey = 'feishin.preferences';
  final _store = SharedPreferencesAsync();
  final _secure = const FlutterSecureStorage();

  String _secret(String id) => 'feishin.password.$id';

  @override
  Future<({List<RemoteProfile> profiles, String? active})>
  loadProfiles() async {
    final raw = await _store.getStringList(_profilesKey) ?? [];
    final profiles = <RemoteProfile>[];
    for (final row in raw) {
      try {
        final data = jsonDecode(row) as WireObject;
        final endpoint = remoteEndpoint(
          data['endpoint'] as String,
          encrypted: (data['endpoint'] as String).startsWith('wss:'),
        );
        if (endpoint == null) continue;
        profiles.add(
          RemoteProfile(
            id: data['id'] as String,
            name: data['name'] as String,
            endpoint: endpoint,
            username: data['username'] as String? ?? '',
            rememberPassword: data['rememberPassword'] as bool? ?? true,
          ),
        );
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return (profiles: profiles, active: await _store.getString(_activeKey));
  }

  Future<void> _writeProfiles(List<RemoteProfile> profiles) =>
      _store.setStringList(
        _profilesKey,
        profiles
            .map(
              (profile) => jsonEncode({
                'id': profile.id,
                'name': profile.name,
                'endpoint': profile.endpoint.toString(),
                'username': profile.username,
                'rememberPassword': profile.rememberPassword,
              }),
            )
            .toList(),
      );

  @override
  Future<String> passwordFor(RemoteProfile profile) async =>
      kIsWeb || !profile.rememberPassword
      ? ''
      : await _secure.read(key: _secret(profile.id)) ?? '';

  @override
  Future<void> saveProfile(RemoteProfile profile, String password) async {
    final saved = (await loadProfiles()).profiles;
    final oldIndex = saved.indexWhere((item) => item.id == profile.id);
    if (!kIsWeb && profile.rememberPassword) {
      await _secure.write(key: _secret(profile.id), value: password);
    }
    if (oldIndex == -1) {
      saved.add(profile);
    } else {
      saved[oldIndex] = profile;
    }
    await _writeProfiles(saved);
    if (!kIsWeb && !profile.rememberPassword) {
      await _secure.delete(key: _secret(profile.id));
    }
  }

  @override
  Future<void> removeProfile(String id) async {
    final saved = await loadProfiles();
    if (!kIsWeb) await _secure.delete(key: _secret(id));
    await _writeProfiles(
      saved.profiles.where((profile) => profile.id != id).toList(),
    );
    if (saved.active == id) await selectProfile(null);
  }

  @override
  Future<void> selectProfile(String? id) =>
      id == null ? _store.remove(_activeKey) : _store.setString(_activeKey, id);

  @override
  Future<RemotePreferences> loadPreferences() async {
    final raw = await _store.getString(_preferencesKey);
    if (raw == null) return const RemotePreferences();
    try {
      final data = jsonDecode(raw) as WireObject;
      return RemotePreferences(
        start: data['start'] == 'library'
            ? Destination.library
            : Destination.playing,
        theme: enumValue(
          ThemePreference.values,
          data['theme'],
          ThemePreference.dark,
        ),
        background: enumValue(
          BackgroundSource.values,
          data['background'],
          BackgroundSource.artwork,
        ),
        timeline: enumValue(
          TimelineStyle.values,
          data['timeline'],
          TimelineStyle.waveform,
        ),
        barDensity: ((data['barDensity'] as int?) ?? 72).clamp(48, 120),
        artworkColors: data['artworkColors'] != false,
        allowArtworkHosts: data['allowArtworkHosts'] == true,
        haptics: data['haptics'] != false,
        reducedMotion: data['reducedMotion'] == true,
        dimBackground: data['dimBackground'] == true,
        blurMiniPlayer: data['blurMiniPlayer'] == true,
        confirmReplace: data['confirmReplace'] != false,
        autoReconnect: data['autoReconnect'] != false,
      );
    } on FormatException {
      return const RemotePreferences();
    } on TypeError {
      return const RemotePreferences();
    }
  }

  @override
  Future<void> savePreferences(RemotePreferences preferences) =>
      _store.setString(
        _preferencesKey,
        jsonEncode({
          'start': preferences.start.name,
          'theme': preferences.theme.name,
          'background': preferences.background.name,
          'timeline': preferences.timeline.name,
          'barDensity': preferences.barDensity,
          'artworkColors': preferences.artworkColors,
          'allowArtworkHosts': preferences.allowArtworkHosts,
          'haptics': preferences.haptics,
          'reducedMotion': preferences.reducedMotion,
          'dimBackground': preferences.dimBackground,
          'blurMiniPlayer': preferences.blurMiniPlayer,
          'confirmReplace': preferences.confirmReplace,
          'autoReconnect': preferences.autoReconnect,
        }),
      );
}
