import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:core/core/base/base_page.dart';
import 'package:core/core/base/base_screen.dart';
import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/button.dart';
import 'package:core/core/ui/atoms/loading_indicator.dart';
import 'package:core/core/ui/molecules/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/value_const.dart';
import '../../../../di/injection_container.dart';
import '../../../../fluttertemplates/auth/login_hero.dart';
import '../../domain/remote.dart';
import '../bloc/home_bloc.dart';
import '../widgets/artwork.dart';
import '../widgets/configuration_views.dart';
import '../widgets/library_queue.dart';
import '../widgets/player.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  @override
  Widget buildBody(BuildContext context) =>
      const SafeArea(child: _HomeScreen());
}

class _HomeScreen extends BaseScreen {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseScreenState<_HomeScreen>
    with WidgetsBindingObserver {
  late final _bloc = context.read<HomeBloc>();
  late final _cache = sl<ArtworkCache>();
  Destination _returnFromSettings = Destination.playing;
  Destination _returnFromProfiles = Destination.playing;
  Destination _queueOrigin = Destination.playing;
  bool _busy = false;

  RemoteRepository get _remote => _bloc.repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _bloc.add(const HomeEvent.lifecycle(true));
      case AppLifecycleState.paused || AppLifecycleState.detached:
        _bloc.add(const HomeEvent.lifecycle(false));
      case AppLifecycleState.inactive || AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget body(BuildContext context) => BlocConsumer<HomeBloc, HomeState>(
    listenWhen: (previous, current) => switch ((previous, current)) {
      (HomeReady(:final activeProfile), HomeReady(activeProfile: final next)) =>
        activeProfile != next,
      _ => false,
    },
    listener: (_, _) => _cache.clear(),
    builder: (_, state) => switch (state) {
      HomeLoading() => const Center(child: LoadingIndicator()),
      final HomeReady ready => _ready(ready),
    },
  );

  void _open(Destination value, {Destination? from}) {
    if (from != null) {
      switch (value) {
        case Destination.settings:
          _returnFromSettings = from;
        case Destination.profiles:
          _returnFromProfiles = from;
        case Destination.queue:
          _queueOrigin = from;
        default:
          break;
      }
    }
    _bloc.add(HomeEvent.navigate(value));
  }

  Destination _backTarget(HomeReady state) => switch (state.destination) {
    Destination.profiles when state.activeProfile != null =>
      _returnFromProfiles,
    Destination.settings => _returnFromSettings,
    Destination.queue => _queueOrigin,
    Destination.library => Destination.playing,
    Destination.playing => Destination.library,
    Destination.profiles => Destination.profiles,
  };

  Widget _ready(HomeReady state) {
    final destination = state.destination;
    final usingShell =
        destination == Destination.library || destination == Destination.queue;
    final profile = state.profiles
        .where((item) => item.id == state.activeProfile)
        .firstOrNull;
    final online = state.session.connection == Connection.connected;
    Uri? artwork(Track track) {
      final image = track.artwork;
      if (image == null || profile == null) return null;
      if (profile.endpoint.scheme == 'wss' && image.scheme == 'http') {
        return null;
      }
      return image.host == profile.endpoint.host ||
              state.preferences.allowArtworkHosts
          ? image
          : null;
    }

    final player = NowPlaying(
      session: state.session,
      repository: _remote,
      cache: _cache,
      artwork: state.session.playback.track == null
          ? null
          : artwork(state.session.playback.track!),
      preferences: state.preferences,
      browse: () => _open(Destination.library),
      queue: () => _open(Destination.queue, from: Destination.playing),
      volume: _volume,
      rating: () => _rate(state.session),
    );
    final title = switch (destination) {
      Destination.playing => ValueConst.playing,
      Destination.library => ValueConst.library,
      Destination.queue => ValueConst.queue,
      Destination.settings => ValueConst.settings,
      Destination.profiles => ValueConst.connections,
    };
    final startRoot = destination == state.preferences.start;
    final canExit =
        destination == Destination.profiles && profile == null || startRoot;
    final settings = SettingsView(
      state: state,
      cache: _cache,
      update: (preferences) => _bloc.add(HomeEvent.preferences(preferences)),
      openProfiles: () =>
          _open(Destination.profiles, from: Destination.settings),
      clearCache: () {
        _cache.clear();
        showSnackBar('Artwork cache cleared.');
      },
    );

    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canExit) _open(_backTarget(state));
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          final medium = constraints.maxWidth >= 600;
          final wide =
              constraints.maxWidth >= 1000 && constraints.maxHeight >= 460;
          final showPlayerPane = wide && usingShell;
          final track = usingShell && !showPlayerPane
              ? state.session.playback.track
              : null;
          final miniHeight = track == null
              ? 0.0
              : _MiniPlayer.heightOf(context, track);
          final blurred = state.preferences.blurMiniPlayer;
          final listInset = blurred ? miniHeight : 0.0;
          final library = LibraryView(
            key: ValueKey(profile?.id),
            repository: _remote,
            bottomInset: listInset,
            session: state.session,
            cache: _cache,
            artwork: artwork,
            onItem: (catalog, item) =>
                _libraryAction(state, catalog, item, artwork),
          );
          final queue = QueueView(
            bottomInset: listInset,
            session: state.session,
            cache: _cache,
            artwork: artwork,
            onBrowse: () => _open(Destination.library),
            enabled: online && !_busy,
            onJump: (entry) => _run(() => _remote.jump(entry.occurrence)),
            onAction: (queue, index) =>
                _queueAction(state.session.generation, queue, index),
            onMove: (entry, to, before) =>
                _run(() => _remote.move(entry, to, before: before)),
          );
          final selected = switch (destination) {
            Destination.playing => showPlayerPane ? 0 : 2,
            Destination.library => 0,
            Destination.queue => 1,
            Destination.settings => 3,
            Destination.profiles => 4,
          };
          final sidebar = IndexedStack(
            index: selected,
            sizing: StackFit.expand,
            children: [
              library,
              queue,
              TickerMode(
                enabled: destination == Destination.playing && !showPlayerPane,
                child: showPlayerPane ? const SizedBox.shrink() : player,
              ),
              settings,
              ProfilesView(
                state: state,
                add: (name, endpoint, username, password, remember) =>
                    _save(name, endpoint, username, password, remember),
                test: _testConnection,
                edit: _edit,
                select: (profile) =>
                    _bloc.add(HomeEvent.selectProfile(profile)),
                remove: _remove,
                disconnect: () => _bloc.add(const HomeEvent.disconnect()),
              ),
            ],
          );
          final leading = switch (destination) {
            Destination.playing => IconButton(
              tooltip: 'Open library',
              onPressed: () => _open(Destination.library),
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            Destination.settings ||
            Destination.profiles when profile != null => IconButton(
              tooltip: 'Back',
              onPressed: () => _open(_backTarget(state)),
              icon: const BackButtonIcon(),
            ),
            _ => null,
          };
          return Column(
            children: [
              _RemoteHeader(
                title: title,
                desktop: profile?.name,
                centered: destination == Destination.playing,
                leading: leading,
                actions: [
                  if (destination == Destination.queue)
                    IconButton(
                      tooltip: ValueConst.clearQueue,
                      icon: const Icon(Icons.playlist_remove_rounded),
                      onPressed:
                          online &&
                              !_busy &&
                              (state.session.playback.queue?.items.isNotEmpty ??
                                  false)
                          ? () => _clear(state.session)
                          : null,
                    ),
                  if (destination != Destination.settings &&
                      destination != Destination.profiles)
                    IconButton(
                      tooltip: ValueConst.settings,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () =>
                          _open(Destination.settings, from: destination),
                    ),
                ],
              ),
              _ConnectionBanner(
                state: state,
                openProfiles: () =>
                    _open(Destination.profiles, from: destination),
                retry: () => _bloc.add(const HomeEvent.reconnect()),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (usingShell && medium)
                      NavigationRail(
                        selectedIndex: destination == Destination.library
                            ? 0
                            : 1,
                        onDestinationSelected: (index) => _open(
                          index == 0 ? Destination.library : Destination.queue,
                        ),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.library_music_outlined),
                            label: Text(ValueConst.library),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.queue_music),
                            label: Text(ValueConst.queue),
                          ),
                        ],
                      ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: blurred ? 0 : miniHeight,
                            ),
                            child: sidebar,
                          ),
                          if (track != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: miniHeight,
                              child: _MiniPlayer(
                                track: track,
                                artwork: artwork(track),
                                cache: _cache,
                                playback: state.session.playback,
                                blurred: blurred,
                                open: () => _open(Destination.playing),
                                toggle: online
                                    ? () => _remote.transport(
                                        state.session.playback.status ==
                                                Playback.playing
                                            ? TransportAction.pause
                                            : TransportAction.play,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showPlayerPane) ...[
                      const VerticalDivider(width: 1),
                      Expanded(child: player),
                    ],
                  ],
                ),
              ),
              if (usingShell && !medium)
                NavigationBar(
                  height: AppSpacing.xl12,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  indicatorColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  elevation: 0,
                  selectedIndex: destination == Destination.library ? 0 : 1,
                  onDestinationSelected: (index) => _open(
                    index == 0 ? Destination.library : Destination.queue,
                  ),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music_rounded),
                      label: ValueConst.library,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.queue_music_outlined),
                      selectedIcon: Icon(Icons.queue_music_rounded),
                      label: ValueConst.queue,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _save(
    String name,
    Uri endpoint,
    String username,
    String password,
    bool remember, {
    String? id,
  }) {
    _bloc.add(
      HomeEvent.editProfile(
        RemoteProfile(
          id: id ?? _bloc.nextProfileId(),
          name: name,
          endpoint: endpoint,
          username: username,
          rememberPassword: remember,
        ),
        password,
      ),
    );
  }

  Future<String?> _testConnection(
    Uri endpoint,
    String username,
    String password,
  ) => _remote.testConnection(
    RemoteProfile(
      id: 'probe',
      name: ValueConst.app,
      endpoint: endpoint,
      username: username,
    ),
    password,
  );

  Future<void> _edit(RemoteProfile profile) async {
    String password;
    try {
      password = await _bloc.configuration.passwordFor(profile);
    } catch (_) {
      password = '';
    }
    if (!mounted) return;
    await showAppBottomSheet<void>(
      title: 'Edit desktop',
      child: Builder(
        builder: (sheet) => ConnectionForm(
          profile: profile,
          initialPassword: password,
          onTest: _testConnection,
          onSave: (name, endpoint, username, password, remember) {
            Navigator.pop(sheet);
            _save(name, endpoint, username, password, remember, id: profile.id);
          },
        ),
      ),
    );
  }

  Future<void> _remove(RemoteProfile profile) async {
    if (await _confirm('Remove desktop?', profile.name, ValueConst.remove) &&
        mounted) {
      _bloc.add(HomeEvent.removeProfile(profile.id));
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await AppDialog.show<bool>(
        context,
        title: title,
        child: Text(message),
        actions: [
          Builder(
            builder: (context) => AppButton(
              label: ValueConst.cancel,
              variant: AppButtonVariant.text,
              onTap: () => Navigator.pop(context, false),
            ),
          ),
          Builder(
            builder: (context) => AppButton(
              label: action,
              onTap: () => Navigator.pop(context, true),
            ),
          ),
        ],
      ) ??
      false;

  Future<void> _run(Future<MutationResult> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await operation();
      if (!mounted) return;
      final message = switch (result) {
        MutationResult.applied => null,
        MutationResult.queueChanged =>
          'Feishin updated the queue. Open Queue to check the result.',
        MutationResult.rejected =>
          'Feishin rejected the change or it is unavailable.',
        MutationResult.unconfirmed =>
          'Check the desktop queue to confirm the change.',
        MutationResult.disconnected =>
          'Connection changed before Feishin confirmed the action.',
      };
      if (message != null) showSnackBar(message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _libraryAction(
    HomeReady state,
    Catalog catalog,
    Track track,
    Uri? Function(Track) artwork,
  ) async {
    final action = await _actions(track.name, [
      (Placement.now, ValueConst.playNow, Icons.play_arrow),
      (Placement.next, ValueConst.playNext, Icons.playlist_play),
      (Placement.last, ValueConst.addQueue, Icons.queue_music),
      if (catalog == Catalog.tracks)
        ('playlist', ValueConst.addPlaylist, Icons.playlist_add),
    ]);
    if (!mounted ||
        action == null ||
        _remote.state.generation != state.session.generation) {
      return;
    }
    if (action == 'playlist') {
      final playlist = await showAppBottomSheet<Track>(
        title: ValueConst.addPlaylist,
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.58,
            child: LibraryView(
              repository: _remote,
              session: state.session,
              cache: _cache,
              artwork: artwork,
              playlistPicker: true,
              onItem: (_, item) => Navigator.pop(context, item),
            ),
          ),
        ),
      );
      if (mounted &&
          playlist != null &&
          _remote.state.generation == state.session.generation) {
        await _run(() => _remote.addToPlaylist(track.id, playlist.id));
      }
    } else if (action is Placement) {
      final queue = _remote.state.playback.queue;
      if (action == Placement.now &&
          (queue?.items.isNotEmpty ?? false) &&
          (state.preferences.confirmReplace ||
              _remote.state.playback.confirmQueueChanges) &&
          !await _confirm(
            ValueConst.replaceQueue,
            ValueConst.replaceMessage,
            ValueConst.playNow,
          )) {
        return;
      }
      if (mounted &&
          _remote.state.generation == state.session.generation &&
          (action != Placement.now ||
              identical(queue, _remote.state.playback.queue))) {
        await _run(() => _remote.play(catalog, track.id, action));
      }
    }
  }

  Future<Object?> _actions(
    String title,
    List<(Object, String, IconData)> actions,
  ) => showAppBottomSheet<Object>(
    title: title,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (action, label, icon) in actions)
            ListTile(
              title: Text(label),
              leading: Icon(icon),
              onTap: () => Navigator.pop(context, action),
            ),
        ],
      ),
    ),
  );

  Future<void> _queueAction(
    int generation,
    QueueSnapshot queue,
    int index,
  ) async {
    final entry = queue.items[index];
    final action = await _actions(entry.track.name, [
      ('jump', ValueConst.playNow, Icons.play_arrow),
      if (index > 0) ('up', 'Move up', Icons.arrow_upward),
      if (index < queue.items.length - 1)
        ('down', 'Move down', Icons.arrow_downward),
      ('remove', ValueConst.remove, Icons.remove_circle_outline),
    ]);
    if (!mounted || action == null) return;
    if (action == 'remove' &&
        queue.current == entry.occurrence &&
        !await _confirm(
          'Remove the current track?',
          'Feishin may skip to the next track.',
          ValueConst.remove,
        )) {
      return;
    }
    if (!mounted ||
        generation != _remote.state.generation ||
        !identical(queue, _remote.state.playback.queue)) {
      return;
    }
    final operation = switch (action) {
      'jump' => () => _remote.jump(entry.occurrence),
      'remove' => () => _remote.remove(entry.occurrence),
      'up' => () => _remote.move(
        entry.occurrence,
        queue.items[index - 1].occurrence,
        before: true,
      ),
      'down' => () => _remote.move(
        entry.occurrence,
        queue.items[index + 1].occurrence,
        before: false,
      ),
      _ => null,
    };
    if (operation != null) await _run(operation);
  }

  Future<void> _clear(SessionState state) async {
    if (await _confirm(
          'Clear the queue?',
          ValueConst.clearMessage,
          ValueConst.clearQueue,
        ) &&
        mounted &&
        state.generation == _remote.state.generation &&
        identical(state.playback.queue, _remote.state.playback.queue)) {
      await _run(_remote.clear);
    }
  }

  Future<void> _rate(SessionState session) async {
    final chosen = await _actions('Track rating', [
      (0, 'Clear rating', Icons.star_border),
      for (var value = 1; value <= 5; value++)
        (value, '$value stars', Icons.star),
    ]);
    if (chosen is int &&
        session.generation == _remote.state.generation &&
        session.playback.occurrence == _remote.state.playback.occurrence) {
      _remote.rate(chosen);
    }
  }

  void _volume() {
    final generation = _remote.state.generation;
    showAppBottomSheet<void>(
      title: ValueConst.volume,
      child: _VolumeControl(
        initial: _remote.state.playback.volume,
        change: (value) {
          if (generation == _remote.state.generation) _remote.setVolume(value);
        },
      ),
    );
  }
}

class _RemoteHeader extends StatelessWidget {
  const _RemoteHeader({
    required this.title,
    required this.desktop,
    required this.centered,
    required this.leading,
    required this.actions,
  });

  final String title;
  final String? desktop;
  final bool centered;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (centered
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: centered ? 0 : -.6,
                  ),
        ),
        if (desktop case final String name)
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        leading == null ? AppSpacing.xl4 : AppSpacing.sm,
        centered ? AppSpacing.xs : AppSpacing.lg,
        AppSpacing.sm,
        centered ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Row(
        children: [
          ?leading,
          Expanded(child: info),
          if (centered && actions.isEmpty)
            const SizedBox(width: AppSpacing.xl10),
          ...actions,
        ],
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.track,
    required this.artwork,
    required this.cache,
    required this.playback,
    required this.open,
    required this.blurred,
    required this.toggle,
  });

  final Track track;
  final Uri? artwork;
  final ArtworkCache cache;
  final PlaybackSnapshot playback;
  final VoidCallback open;
  final bool blurred;

  final VoidCallback? toggle;

  static double heightOf(BuildContext context, Track track) {
    final scaler = MediaQuery.textScalerOf(context);
    final typography = Theme.of(context).textTheme;
    double lineHeight(TextStyle? style, double nominalHeight) {
      final size = style?.fontSize ?? AppSpacing.md;
      return scaler.scale(size) * (style?.height ?? nominalHeight / size);
    }

    final textHeight =
        lineHeight(typography.titleSmall, AppSpacing.xl2) +
        (track.artist.isEmpty
            ? 0
            : lineHeight(typography.bodySmall, AppSpacing.lg));
    return math.max(AppSpacing.xl8, textHeight.ceilToDouble()) +
        AppSpacing.lg +
        (track.duration != null ? AppSpacing.xs4 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPlaying = playback.status == Playback.playing;
    final duration = track.duration?.inMilliseconds ?? 0;
    final progress = duration > 0
        ? (playback.position.inMilliseconds / duration).clamp(0.0, 1.0)
        : 0.0;
    final surface = Material(
      color: blurred
          ? colors.surfaceContainerHigh.withValues(alpha: 0.82)
          : colors.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: open,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Row(
                        spacing: AppSpacing.base,
                        children: [
                          SizedBox.square(
                            dimension: AppSpacing.xl8,
                            child: CoverImage(
                              cache: cache,
                              url: artwork,
                              pixels: 128,
                              radius: BorderRadius.zero,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (track.artist.isNotEmpty)
                                  Text(
                                    track.artist,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: toggle,
                  iconSize: AppSpacing.xl4,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs3),
              ],
            ),
          ),
          if (duration > 0)
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.xs4,
                borderRadius: BorderRadius.zero,
                backgroundColor: colors.outlineVariant,
                color: colors.primary,
              ),
            ),
        ],
      ),
    );
    if (!blurred) return surface;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppSpacing.lg, sigmaY: AppSpacing.lg),
        child: surface,
      ),
    );
  }
}

class _VolumeControl extends StatefulWidget {
  const _VolumeControl({required this.initial, required this.change});

  final double initial;
  final ValueChanged<double> change;

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('${_value.round()}%'),
      Slider(
        value: _value,
        max: 100,
        divisions: 100,
        onChanged: (value) => setState(() => _value = value),
        onChangeEnd: widget.change,
        semanticFormatterCallback: (value) => '${value.round()} percent',
      ),
    ],
  );
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.state,
    required this.openProfiles,
    required this.retry,
  });

  final HomeReady state;
  final VoidCallback openProfiles;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final status = state.session.connection;
    if (state.message == null &&
        (status == Connection.connected ||
            state.destination == Destination.profiles &&
                state.activeProfile == null)) {
      return const SizedBox.shrink();
    }
    final label =
        state.message ??
        state.session.notice ??
        switch (status) {
          Connection.connecting => 'Connecting to Feishin…',
          Connection.reconnecting => 'Reconnecting…',
          Connection.authFailed => 'Authentication failed',
          Connection.disconnected => 'Disconnected',
          Connection.connected => 'Connected',
        };
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ListTile(
        title: Semantics(liveRegion: true, child: Text(label)),
        trailing: status == Connection.connecting || state.saving
            ? const SizedBox.square(
                dimension: AppSpacing.xl4,
                child: LoadingIndicator(),
              )
            : Wrap(
                children: [
                  if (state.activeProfile != null &&
                      status != Connection.authFailed)
                    IconButton(
                      tooltip: ValueConst.retry,
                      onPressed: retry,
                      icon: const Icon(Icons.refresh),
                    ),
                  if (state.destination != Destination.profiles)
                    IconButton(
                      tooltip: ValueConst.connections,
                      onPressed: openProfiles,
                      icon: const Icon(Icons.link),
                    ),
                ],
              ),
      ),
    );
  }
}
