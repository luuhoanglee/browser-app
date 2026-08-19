import 'package:browser_app/data/repositories/tab_repository_impl.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_event.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<TabBloc> newBloc() async {
    final bloc = TabBloc(TabRepositoryImpl());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return bloc;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('adding media updates both activeTab and focusedTab', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final tabId = bloc.state.activeTab!.id;
    final resource = LoadedResource(
      url: WebUri('https://cdn.example.com/video/master.m3u8'),
    );

    bloc.add(AddLoadedResourceEvent(tabId, resource));
    await settle();

    expect(bloc.state.activeTab!.loadedResources, contains(resource));
    expect(bloc.state.focusedTab!.loadedResources, contains(resource));
    expect(
      bloc.state.tabs.singleWhere((tab) => tab.id == tabId).loadedResources,
      contains(resource),
    );
  });

  test('clearing media updates both activeTab and focusedTab', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final tabId = bloc.state.activeTab!.id;
    final resource = LoadedResource(
      url: WebUri('https://cdn.example.com/video/master.m3u8'),
    );
    bloc.add(AddLoadedResourceEvent(tabId, resource));
    await settle();

    bloc.add(ClearLoadedResourcesEvent(tabId));
    await settle();

    expect(bloc.state.activeTab!.loadedResources, isEmpty);
    expect(bloc.state.focusedTab!.loadedResources, isEmpty);
    expect(
      bloc.state.tabs.singleWhere((tab) => tab.id == tabId).loadedResources,
      isEmpty,
    );
  });

  test('loaded resources are deduplicated and capped per tab', () async {
    final bloc = await newBloc();
    addTearDown(bloc.close);
    final tabId = bloc.state.activeTab!.id;

    for (var index = 0; index < TabBloc.maxLoadedResourcesPerTab + 5; index++) {
      bloc.add(
        AddLoadedResourceEvent(
          tabId,
          LoadedResource(url: WebUri('https://cdn.example.com/$index.mp4')),
        ),
      );
    }
    bloc.add(
      AddLoadedResourceEvent(
        tabId,
        LoadedResource(url: WebUri('https://cdn.example.com/204.mp4')),
      ),
    );
    await settle();

    final resources = bloc.state.activeTab!.loadedResources;
    expect(resources, hasLength(TabBloc.maxLoadedResourcesPerTab));
    expect(resources.first.url.toString(), endsWith('/5.mp4'));
    expect(
      resources.where((item) => item.url.toString().endsWith('/204.mp4')),
      hasLength(1),
    );
  });
}
