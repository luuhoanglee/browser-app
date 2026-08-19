import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/storage_service.dart';
import '../models/quick_access_site.dart';
import 'quick_access_event.dart';
import 'quick_access_state.dart';

class QuickAccessBloc extends Bloc<QuickAccessEvent, QuickAccessState> {
  QuickAccessBloc() : super(const QuickAccessState()) {
    on<QuickAccessLoadEvent>(_onLoad);
    on<QuickAccessAddEvent>(_onAdd);
    on<QuickAccessRemoveEvent>(_onRemove);
    on<QuickAccessReorderEvent>(_onReorder);
  }

  Future<void> _onLoad(
      QuickAccessLoadEvent event, Emitter<QuickAccessState> emit) async {
    final sites = await StorageService.loadQuickAccessSites();
    if (sites.isEmpty) {
      // Seed defaults on first launch
      final defaults = QuickAccessSite.defaults;
      await StorageService.saveQuickAccessSites(defaults);
      emit(state.copyWith(sites: defaults, isLoaded: true));
    } else {
      emit(state.copyWith(sites: sites, isLoaded: true));
    }
  }

  Future<void> _onAdd(
      QuickAccessAddEvent event, Emitter<QuickAccessState> emit) async {
    final updated = List<QuickAccessSite>.from(state.sites)..add(event.site);
    await StorageService.saveQuickAccessSites(updated);
    emit(state.copyWith(sites: updated));
  }

  Future<void> _onRemove(
      QuickAccessRemoveEvent event, Emitter<QuickAccessState> emit) async {
    final updated =
        state.sites.where((s) => s.id != event.id).toList();
    await StorageService.saveQuickAccessSites(updated);
    emit(state.copyWith(sites: updated));
  }

  Future<void> _onReorder(
      QuickAccessReorderEvent event, Emitter<QuickAccessState> emit) async {
    final list = List<QuickAccessSite>.from(state.sites);
    final item = list.removeAt(event.oldIndex);
    final insertAt =
        event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    list.insert(insertAt, item);
    await StorageService.saveQuickAccessSites(list);
    emit(state.copyWith(sites: list));
  }
}
