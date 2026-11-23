import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/button.dart';
import 'package:core/core/ui/atoms/dropdown_menu.dart';
import 'package:flutter/material.dart';

import '../../../../constants/value_const.dart';
import '../../../../fluttertemplates/auth/login_hero.dart';
import '../../../../fluttertemplates/must_haves/settings_page/settings_page_1.dart';
import '../../domain/remote.dart';
import '../bloc/home_bloc.dart';
import 'artwork.dart';
import 'timeline.dart';

class ProfilesView extends StatelessWidget {
  const ProfilesView({
    super.key,
    required this.state,
    required this.add,
    required this.test,
    required this.edit,
    required this.select,
    required this.remove,
    required this.disconnect,
  });

  final HomeReady state;
  final void Function(String, Uri, String, String, bool) add;
  final Future<String?> Function(Uri endpoint, String username, String password)
  test;
  final ValueChanged<RemoteProfile> edit;
  final ValueChanged<RemoteProfile> select;
  final ValueChanged<RemoteProfile> remove;
  final VoidCallback disconnect;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        children: [
          Text(
            ValueConst.connect,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.base),
          const Text(ValueConst.connectInstruction),
          const SizedBox(height: AppSpacing.xl4),
          for (final profile in state.profiles)
            Card(
              child: ListTile(
                title: Text(profile.name),
                subtitle: Text(profile.endpoint.authority),
                selected: state.activeProfile == profile.id,
                onTap: state.saving ? null : () => select(profile),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit ${profile.name}',
                      onPressed: state.saving ? null : () => edit(profile),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remove ${profile.name}',
                      onPressed: state.saving ? null : () => remove(profile),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          if (state.activeProfile != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: ValueConst.disconnect,
                variant: AppButtonVariant.text,
                onTap: disconnect,
              ),
            ),
          if (state.profiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Add a desktop',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          IgnorePointer(
            ignoring: state.saving,
            child: ConnectionForm(onSave: add, onTest: test),
          ),
        ],
      ),
    ),
  );
}

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.state,
    required this.update,
    required this.openProfiles,
    required this.cache,
    required this.clearCache,
  });

  final HomeReady state;
  final ValueChanged<RemotePreferences> update;
  final VoidCallback openProfiles;
  final ArtworkCache cache;
  final VoidCallback clearCache;

  @override
  Widget build(BuildContext context) {
    final preferences = state.preferences;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl6),
          children: [
            SettingsSection(
              title: ValueConst.connections,
              rows: [
                ListTile(
                  title: const Text('Saved desktops'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: openProfiles,
                ),
                SwitchListTile(
                  title: const Text('Reconnect automatically'),
                  value: preferences.autoReconnect,
                  onChanged: (value) =>
                      update(preferences.copyWith(autoReconnect: value)),
                ),
              ],
            ),
            SettingsSection(
              title: 'Appearance',
              rows: [
                _choice(
                  'Start screen',
                  const [Destination.playing, Destination.library],
                  preferences.start,
                  (value) => value == Destination.playing
                      ? ValueConst.playing
                      : ValueConst.library,
                  (value) => update(preferences.copyWith(start: value)),
                ),
                _choice(
                  'Theme',
                  ThemePreference.values,
                  preferences.theme,
                  _label,
                  (value) => update(preferences.copyWith(theme: value)),
                ),
                _choice(
                  'Player background',
                  BackgroundSource.values,
                  preferences.background,
                  (value) => switch (value) {
                    BackgroundSource.artwork => 'Album artwork',
                    BackgroundSource.device => 'Device palette',
                    BackgroundSource.theme => 'Static theme',
                  },
                  (value) => update(preferences.copyWith(background: value)),
                ),
                SwitchListTile(
                  title: const Text('Dim player background'),
                  value: preferences.dimBackground,
                  onChanged: (value) =>
                      update(preferences.copyWith(dimBackground: value)),
                ),
                SwitchListTile(
                  title: const Text('Blur mini-player background'),
                  subtitle: const Text(
                    'Show the list through a translucent background.',
                  ),
                  value: preferences.blurMiniPlayer,
                  onChanged: (value) =>
                      update(preferences.copyWith(blurMiniPlayer: value)),
                ),
                SwitchListTile(
                  title: const Text('Reduce motion'),
                  value: preferences.reducedMotion,
                  onChanged: (value) =>
                      update(preferences.copyWith(reducedMotion: value)),
                ),
              ],
            ),
            SettingsSection(
              title: 'Waveform',
              rows: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Card(
                    child: _TimelinePreview(preferences: preferences),
                  ),
                ),
                _choice(
                  'Seekbar style',
                  TimelineStyle.values,
                  preferences.timeline,
                  (value) => value == TimelineStyle.standard
                      ? 'Standard'
                      : 'Generated waveform',
                  (value) => update(preferences.copyWith(timeline: value)),
                ),
                if (preferences.timeline == TimelineStyle.waveform) ...[
                  _choice(
                    'Bar density',
                    const [48, 72, 96, 120],
                    preferences.barDensity,
                    (value) => '$value bars',
                    (value) => update(preferences.copyWith(barDensity: value)),
                  ),
                  SwitchListTile(
                    title: const Text('Use artwork colors'),
                    value: preferences.artworkColors,
                    onChanged: (value) =>
                        update(preferences.copyWith(artworkColors: value)),
                  ),
                ],
                SwitchListTile(
                  title: const Text('Haptic feedback when seeking'),
                  value: preferences.haptics,
                  onChanged: (value) =>
                      update(preferences.copyWith(haptics: value)),
                ),
              ],
            ),
            SettingsSection(
              title: 'Playback controls',
              rows: [
                SwitchListTile(
                  title: const Text('Confirm before replacing the queue'),
                  subtitle: const Text(
                    'Feishin can also require confirmation.',
                  ),
                  value: preferences.confirmReplace,
                  onChanged: (value) =>
                      update(preferences.copyWith(confirmReplace: value)),
                ),
              ],
            ),
            const SettingsSection(
              title: 'Android integration',
              rows: [
                ListTile(
                  title: Text('In-app controls'),
                  subtitle: Text('Audio plays on your desktop.'),
                ),
              ],
            ),
            SettingsSection(
              title: 'Storage and caching',
              rows: [
                SwitchListTile(
                  title: const Text(ValueConst.artworkTrust),
                  subtitle: const Text(ValueConst.artworkTrustHint),
                  value: preferences.allowArtworkHosts,
                  onChanged: (value) =>
                      update(preferences.copyWith(allowArtworkHosts: value)),
                ),
                ListTile(
                  title: const Text('Clear artwork cache'),
                  subtitle: Text('${cache.count} cached artwork requests'),
                  onTap: clearCache,
                  trailing: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            SettingsSection(
              title: 'Diagnostics and About',
              rows: [
                ListTile(
                  title: const Text('Connection state'),
                  subtitle: Text(_label(state.session.connection)),
                ),
                ListTile(
                  title: const Text(ValueConst.app),
                  subtitle: const Text(
                    'Android controller for Feishin desktop',
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: ValueConst.app,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice<T>(
    String title,
    List<T> options,
    T value,
    String Function(T) label,
    ValueChanged<T> change,
  ) => AppDropdownMenu<T>(
    value: value,
    onSelected: change,
    items: [
      for (final option in options)
        AppDropdownItem(value: option, label: label(option)),
    ],
    trigger: ListTile(
      title: Text(title),
      subtitle: Text(label(value)),
      trailing: const Icon(Icons.arrow_drop_down),
    ),
  );

  String _label(Enum value) =>
      '${value.name[0].toUpperCase()}${value.name.substring(1)}';
}

class _TimelinePreview extends StatefulWidget {
  const _TimelinePreview({required this.preferences});

  final RemotePreferences preferences;

  @override
  State<_TimelinePreview> createState() => _TimelinePreviewState();
}

class _TimelinePreviewState extends State<_TimelinePreview> {
  var _time = const Duration(seconds: 45);
  static const _track = (
    id: 'preview',
    name: 'Preview',
    artist: '',
    album: null,
    serverId: null,
    serverType: null,
    occurrence: 'preview',
    duration: Duration(minutes: 3, seconds: 48),
    artwork: null,
    favorite: null,
    rating: null,
    year: null,
    songCount: null,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(
      children: [
        const Text('Live preview'),
        Timeline(
          snapshot: PlaybackSnapshot(track: _track, position: _time),
          generation: 0,
          clock: () => Duration.zero,
          preferences: widget.preferences,
          enabled: true,
          onSeek: (time, _, _) => setState(() => _time = time),
        ),
      ],
    ),
  );
}
