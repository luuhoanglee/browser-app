import 'package:browser_app/features/media/bloc/media_bloc.dart';
import 'package:browser_app/features/media/bloc/media_event.dart';
import 'package:browser_app/features/media/bloc/media_state.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the HLS playlist and hides transport stream fragments', () async {
    final bloc = MediaBloc();
    addTearDown(bloc.close);
    const playlist = 'https://cdn.example.com/hls/video/master.m3u8';
    const segment = 'https://cdn.example.com/hls/video/segment-001.ts';

    bloc.add(
      MediaExtractFromResources([
        LoadedResource(url: WebUri(playlist)),
        LoadedResource(url: WebUri(segment)),
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as MediaLoaded;
    expect(state.result.videos, [playlist]);
  });
}
