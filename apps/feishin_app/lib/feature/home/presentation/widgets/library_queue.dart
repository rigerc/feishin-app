import 'package:core/core/theme/app_radius.dart';
import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/button.dart';
import 'package:core/core/ui/atoms/loading_indicator.dart';
import 'package:core/core/ui/molecules/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/value_const.dart';
import '../../../../fluttertemplates/layouts/reorderable_list.dart';
import '../../../../fluttertemplates/search/search_results.dart';
import '../../domain/remote.dart';
import '../bloc/catalog_cubit.dart';
import 'artwork.dart';
import 'timeline.dart';

String catalogLabel(Catalog catalog) => switch (catalog) {
  Catalog.tracks => 'Tracks',
  Catalog.albums => 'Albums',
  Catalog.playlists => 'Playlists',
};

class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    required this.repository,
    required this.session,
    required this.cache,
    required this.artwork,
    required this.onItem,
    this.playlistPicker = false,
    this.bottomInset = 0,
  });

  final RemoteRepository repository;
  final SessionState session;
  final ArtworkCache cache;
  final Uri? Function(Track) artwork;
  final void Function(Catalog, Track) onItem;
  final bool playlistPicker;
  final double bottomInset;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late Catalog _selected = widget.playlistPicker
      ? Catalog.playlists
      : Catalog.tracks;
  final _seen = <Catalog>{};

  @override
  Widget build(BuildContext context) {
    _seen.add(_selected);
    final categories = widget.playlistPicker
        ? const [Catalog.playlists]
        : Catalog.values;
    return Column(
      children: [
        if (!widget.playlistPicker)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final type in categories)
                    ChoiceChip(
                      label: Text(catalogLabel(type)),
                      showCheckmark: false,
                      selected: _selected == type,
                      onSelected: (_) => setState(() => _selected = type),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: categories.indexOf(_selected),
            children: [
              for (final category in categories)
                if (_seen.contains(category))
                  _CatalogList(
                    key: ValueKey(category),
                    category: category,
                    repository: widget.repository,
                    session: widget.session,
                    cache: widget.cache,
                    artwork: widget.artwork,
                    onItem: (item) => widget.onItem(category, item),
                    picker: widget.playlistPicker,
                    bottomInset: widget.bottomInset,
                  )
                else
                  const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogList extends StatefulWidget {
  const _CatalogList({
    super.key,
    required this.category,
    required this.repository,
    required this.session,
    required this.cache,
    required this.artwork,
    required this.onItem,
    required this.picker,
    required this.bottomInset,
  });

  final Catalog category;
  final RemoteRepository repository;
  final SessionState session;
  final ArtworkCache cache;
  final Uri? Function(Track) artwork;
  final ValueChanged<Track> onItem;
  final bool picker;
  final double bottomInset;

  @override
  State<_CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends State<_CatalogList> {
  late final _catalog = CatalogCubit(
    widget.repository,
    initial: widget.category,
  );
  bool get _online => widget.session.connection == Connection.connected;

  @override
  void initState() {
    super.initState();
    if (_online) _catalog.change();
  }

  @override
  void didUpdateWidget(_CatalogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_online &&
        (oldWidget.session.connection != Connection.connected ||
            oldWidget.session.generation != widget.session.generation)) {
      _catalog.change();
    }
  }

  @override
  void dispose() {
    _catalog.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CatalogCubit, CatalogViewState>(
    bloc: _catalog,
    builder: (_, state) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: CatalogSearch(
            label: 'Search ${widget.category.name}',
            onChanged: (value) =>
                _catalog.change(query: value, immediately: false),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Expanded(
          child: switch ((
            _online,
            state.loading,
            state.items.isEmpty,
            state.failed,
          )) {
            (false, _, true, _) => const Center(
              child: Text('Connect to load the library.'),
            ),
            (_, true, true, _) => const Center(child: LoadingIndicator()),
            (_, _, true, false) => Center(
              child: EmptyState(
                title: state.query.isEmpty
                    ? ValueConst.noItems
                    : ValueConst.noResults,
                subtitle: state.query.isEmpty
                    ? ValueConst.emptyTip
                    : 'Try a different search.',
                iconData: Icons.library_music_outlined,
                actions: _online
                    ? [
                        AppButton(
                          label: 'Refresh',
                          onTap: () => _catalog.change(),
                        ),
                      ]
                    : null,
              ),
            ),
            _ => RefreshIndicator(
              onRefresh: () async => _catalog.change(),
              child: widget.category == Catalog.albums && state.items.isNotEmpty
                  ? _albums(context, state)
                  : _rows(state),
            ),
          },
        ),
      ],
    ),
  );

  Widget _rows(CatalogViewState state) => ListView.builder(
    padding: EdgeInsets.only(bottom: widget.bottomInset),
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: state.items.length + 1,
    itemBuilder: (context, index) {
      if (index == state.items.length) return _footer(state);
      final item = state.items[index];
      return MediaRow(
        key: ValueKey(item.id),
        track: item,
        url: widget.artwork(item),
        cache: widget.cache,
        onTap: _online ? () => widget.onItem(item) : null,
        trailing: widget.picker
            ? const Icon(Icons.chevron_right)
            : IconButton(
                tooltip: 'Actions for ${item.name}',
                icon: const Icon(Icons.more_vert),
                onPressed: _online ? () => widget.onItem(item) : null,
              ),
      );
    },
  );

  Widget _albums(BuildContext context, CatalogViewState state) =>
      CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.base,
                childAspectRatio: 0.76,
              ),
              itemCount: state.items.length,
              itemBuilder: (_, index) {
                final track = state.items[index];
                return InkWell(
                  onTap: _online ? () => widget.onItem(track) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CoverImage(
                          cache: widget.cache,
                          url: widget.artwork(track),
                          pixels: 350,
                          icon: Icons.album,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _footer(state)),
          SliverToBoxAdapter(child: SizedBox(height: widget.bottomInset)),
        ],
      );

  Widget _footer(CatalogViewState state) {
    if (!_online || !state.more) return const SizedBox(height: AppSpacing.lg);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: AppButton(
          label: state.failed ? ValueConst.retry : ValueConst.loadMore,
          variant: AppButtonVariant.secondary,
          state: state.loading ? AppButtonState.loading : AppButtonState.idle,
          onTap: _catalog.more,
        ),
      ),
    );
  }
}

class MediaRow extends StatelessWidget {
  const MediaRow({
    super.key,
    required this.track,
    required this.url,
    required this.cache,
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  final Track track;
  final Uri? url;
  final ArtworkCache cache;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) => ListTile(
    selected: selected,
    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
    leading: SizedBox.square(
      dimension: AppSpacing.xl10,
      child: CoverImage(
        cache: cache,
        url: url,
        pixels: 128,
        radius: AppRadius.md,
      ),
    ),
    title: Text(
      track.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      [
        if (selected) ValueConst.playing,
        if (track.artist.isNotEmpty) track.artist,
        if (track.year case final int year when year > 0) '$year',
        if (track.songCount case final int count) '$count tracks',
        if (track.duration case final Duration duration) timeLabel(duration),
      ].join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    onTap: onTap,
    trailing: trailing,
  );
}

class QueueView extends StatefulWidget {
  const QueueView({
    super.key,
    required this.session,
    required this.cache,
    required this.artwork,
    required this.onJump,
    required this.onAction,
    required this.onMove,
    required this.onBrowse,
    required this.enabled,
    this.bottomInset = 0,
  });

  final SessionState session;
  final ArtworkCache cache;
  final Uri? Function(Track) artwork;
  final ValueChanged<QueueEntry> onJump;
  final void Function(QueueSnapshot, int) onAction;
  final void Function(String, String, bool) onMove;
  final VoidCallback onBrowse;
  final bool enabled;
  final double bottomInset;

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  QueueSnapshot? _dragQueue;

  @override
  Widget build(BuildContext context) {
    final queue = widget.session.playback.queue;
    if (queue == null || queue.items.isEmpty) {
      return Center(
        child: EmptyState(
          title: queue == null
              ? ValueConst.queueUnavailable
              : ValueConst.noQueue,
          iconData: Icons.queue_music,
          actions: [AppButton(label: 'Browse library', onTap: widget.onBrowse)],
        ),
      );
    }
    final items = queue.items;
    return QueueReorderList(
      count: items.length,
      padding: EdgeInsets.only(bottom: widget.bottomInset),
      start: (_) => _dragQueue = queue,
      reorder: (from, to) {
        if (!widget.enabled || !identical(queue, _dragQueue)) return;
        final destination = to;
        if (from == destination) return;
        widget.onMove(
          items[from].occurrence,
          items[destination].occurrence,
          destination < from,
        );
      },
      row: (context, index) {
        final item = items[index];
        return MediaRow(
          key: ValueKey(item.occurrence),
          track: item.track,
          url: widget.artwork(item.track),
          cache: widget.cache,
          selected: queue.current == item.occurrence,
          onTap: widget.enabled ? () => widget.onJump(item) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Queue actions for ${item.track.name}',
                onPressed: widget.enabled
                    ? () => widget.onAction(queue, index)
                    : null,
                icon: const Icon(Icons.more_vert),
              ),
              if (widget.enabled)
                ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox.square(
                    dimension: AppSpacing.xl10,
                    child: Icon(Icons.drag_handle),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
