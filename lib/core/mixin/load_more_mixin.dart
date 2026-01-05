import 'package:flutter/material.dart';

mixin LoadMoreMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();

  Future<void> onLoadMore();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {
      onLoadMore();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
