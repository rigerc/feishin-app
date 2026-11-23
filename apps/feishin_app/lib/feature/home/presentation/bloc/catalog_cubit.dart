import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/remote.dart';

typedef CatalogViewState = ({
  Catalog catalog,
  String query,
  List<Track> items,
  bool loading,
  bool more,
  bool failed,
});

class CatalogCubit extends Cubit<CatalogViewState> {
  CatalogCubit(this.repository, {Catalog initial = Catalog.tracks})
    : super((
        catalog: initial,
        query: '',
        items: const [],
        loading: false,
        more: true,
        failed: false,
      ));

  final RemoteRepository repository;
  Timer? _debounce;
  var _generation = 0;
  var _offset = 0;
  var _noProgress = 0;

  void change({Catalog? catalog, String? query, bool immediately = true}) {
    _debounce?.cancel();
    final generation = ++_generation;
    _offset = 0;
    _noProgress = 0;
    emit((
      catalog: catalog ?? state.catalog,
      query: query?.trim() ?? state.query,
      items: const [],
      loading: true,
      more: true,
      failed: false,
    ));
    if (immediately) {
      unawaited(_read(generation));
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => unawaited(_read(generation)),
      );
    }
  }

  Future<void> more() async {
    if (state.loading || !state.more) return;
    await _read(_generation);
  }

  Future<void> _read(int generation) async {
    final connection = repository.state.generation;
    final current = state;
    emit((
      catalog: current.catalog,
      query: current.query,
      items: current.items,
      loading: true,
      more: current.more,
      failed: false,
    ));
    final page = await repository.browse(
      current.catalog,
      _offset,
      current.query,
    );
    if (isClosed ||
        generation != _generation ||
        connection != repository.state.generation) {
      return;
    }
    final seen = current.items.map((item) => item.id).toSet();
    final added = page?.items.where((item) => seen.add(item.id)).toList() ?? [];
    _offset += page?.received ?? 0;
    _noProgress = added.isEmpty ? _noProgress + 1 : 0;
    emit((
      catalog: current.catalog,
      query: current.query,
      items: List.unmodifiable([...current.items, ...added]),
      loading: false,
      more:
          page == null || page.hasMore && page.received > 0 && _noProgress < 2,
      failed: page == null,
    ));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
