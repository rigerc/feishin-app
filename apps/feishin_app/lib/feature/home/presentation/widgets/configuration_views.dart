import 'package:core/core/theme/app_radius.dart';
import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/badge.dart';
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
    required this.create,
    required this.test,
    required this.edit,
    required this.select,
    required this.remove,
    required this.disconnect,
  });

  final HomeReady state;
  final void Function(String, Uri, String, String, bool) add;
  final VoidCallback create;
  final Future<String?> Function(Uri endpoint, String username, String password)
  test;
  final ValueChanged<RemoteProfile> edit;
  final ValueChanged<RemoteProfile> select;
  final ValueChanged<RemoteProfile> remove;
  final VoidCallback disconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onboarding = state.profiles.isEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl4,
            AppSpacing.base,
            AppSpacing.xl4,
            AppSpacing.xl6,
          ),
          children: [
            if (onboarding) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: AppRadius.xl,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Icon(
                      Icons.settings_remote_rounded,
                      size: AppSpacing.xl6,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                ValueConst.connect,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ValueConst.connectInstruction,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl4),
              IgnorePointer(
                ignoring: state.saving,
                child: ConnectionForm(onSave: add, onTest: test),
              ),
            ] else ...[
              SettingsSection(
                title: ValueConst.savedDesktops,
                rows: [
                  for (final profile in state.profiles)
                    _ProfileTile(
                      profile: profile,
                      active: state.activeProfile == profile.id,
                      connection: state.session.connection,
                      enabled: !state.saving,
                      select: () => select(profile),
                      edit: () => edit(profile),
                      remove: () => remove(profile),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppButton(
                    label: ValueConst.addDesktop,
                    variant: AppButtonVariant.secondary,
                    leadingIcon: const Icon(Icons.add_rounded),
                    state: state.saving
                        ? AppButtonState.disabled
                        : AppButtonState.idle,
                    onTap: create,
                  ),
                  if (state.activeProfile != null)
                    AppButton(
                      label: ValueConst.disconnect,
                      variant: AppButtonVariant.text,
                      leadingIcon: const Icon(Icons.link_off_rounded),
                      onTap: disconnect,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.active,
    required this.connection,
    required this.enabled,
    required this.select,
    required this.edit,
    required this.remove,
  });

  final RemoteProfile profile;
  final bool active;
  final Connection connection;
  final bool enabled;
  final VoidCallback select;
  final VoidCallback edit;
  final VoidCallback remove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final encrypted = profile.endpoint.scheme == 'wss';
    final online = active && connection == Connection.connected;
    return ListTile(
      selected: active,
      selectedColor: scheme.onSurface,
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.xs,
      ),
      isThreeLine: active,
      leading: Tooltip(
        message: encrypted ? ValueConst.encrypted : ValueConst.lan,
        child: CircleAvatar(
          backgroundColor: active
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          foregroundColor: active
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          child: Icon(
            encrypted ? Icons.lock_outline_rounded : Icons.computer_rounded,
          ),
        ),
      ),
      title: Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs3,
        children: [
          Text(
            profile.endpoint.authority,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (active)
            AppBadge(
              text: online ? ValueConst.connected : ValueConst.active,
              intent: online ? AppBadgeIntent.success : AppBadgeIntent.neutral,
              size: AppBadgeSize.small,
            ),
        ],
      ),
      onTap: enabled ? select : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit ${profile.name}',
            onPressed: enabled ? edit : null,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove ${profile.name}',
            onPressed: enabled ? remove : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl6,
          ),
          children: [
            SettingsSection(
              title: ValueConst.connections,
              rows: [
                ListTile(
                  title: const Text(ValueConst.savedDesktops),
                  subtitle: Text(
                    state.profiles
                            .where((item) => item.id == state.activeProfile)
                            .firstOrNull
                            ?.name ??
                        ValueConst.disconnected,
                  ),
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
                _TimelinePreview(preferences: preferences),
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
        Text(
          'Live preview',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
