import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_state.dart';
import '../bloc/search_event.dart';
import '../search_service.dart';

class SearchPage extends StatefulWidget {
  final Function(String) onSearch;
  final String? initialUrl;

  const SearchPage({
    super.key,
    required this.onSearch,
    this.initialUrl,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late SearchBloc _searchBloc;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Set initial URL if provided
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _controller.text = widget.initialUrl!;
      // Select all text for easy editing
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    // Đợi animation hoàn tất rồi mới focus
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchBloc = context.read<SearchBloc>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Safari Search Bar
                    _buildSafariSearchBar(state),

                    const SizedBox(height: 20),

                    // Content Area with rounded corners
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 16),

                            // Search Suggestions Section (hiển thị khi có query)
                            if (state.query.isNotEmpty && state.searchSuggestions.isNotEmpty)
                              _buildSuggestionsSection(state),

                            // Recent History Section (chỉ hiển thị khi không có query)
                            if (state.query.isEmpty && state.searchHistory.isNotEmpty)
                              _buildRecentSection(state),

                            // Trending Searches Section (chỉ hiển thị khi không có query)
                            if (state.query.isEmpty && state.trendingSearches.isNotEmpty)
                              _buildTrendingSection(state),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafariSearchBar(SearchState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Search Engine Icon with Dropdown
          GestureDetector(
            onTap: () {
              _showEngineSelector(context, state);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getEngineIcon(state.selectedEngine),
                  size: 20,
                  color: _getEngineColor(state.selectedEngine),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text Field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                hintText: 'Search or enter URL',
                hintStyle: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 17,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {});
                // Trigger suggestions update
                _searchBloc.add(UpdateQueryEvent(value));
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  final query = value.trim();
                  // Lưu vào search history
                  _searchBloc.add(PerformSearchEvent(query));
                  widget.onSearch(query);
                  Navigator.pop(context);
                }
              },
            ),
          ),
          
          // Clear button when typing
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.cancel,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          
          // Cancel Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                size: 22,
                color: Color(0xFF8E8E93),
              ),
              const SizedBox(width: 8),
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (state.isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...state.searchSuggestions.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final query = entry.value;
            return _buildSuggestionItem(query, index);
          }).toList(),
      ],
    );
  }

  Widget _buildSuggestionItem(String query, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          widget.onSearch(query);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Icon(
                Icons.arrow_upward,
                size: 16,
                color: Color(0xFF34C759),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<SearchBloc>().add(ClearSearchHistoryEvent());
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 3),

        ...state.searchHistory.take(10).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final query = entry.value;
          return _buildRecentItem(query, index);
        }).toList(),
      ],
    );
  }

  Widget _buildTrendingSection(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Trending Search',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        if (state.isLoadingTrending)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...state.trendingSearches.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final query = entry.value;
            return _buildTrendingItem(query, index);
          }).toList(),
      ],
    );
  }

  Widget _buildTrendingItem(String query, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          widget.onSearch(query);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Icon(
                Icons.arrow_upward,
                size: 16,
                color: Color(0xFF34C759),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String query, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          widget.onSearch(query);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.language,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              GestureDetector(
                onTap: () {
                  context.read<SearchBloc>().add(
                    RemoveSearchHistoryEvent(query),
                  );
                },
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEngineSelector(BuildContext context, SearchState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: _searchBloc,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Chọn công cụ tìm kiếm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...SearchEngine.values.map((engine) {
                final isSelected = engine == state.selectedEngine;
                return ListTile(
                  leading: Icon(
                    _getEngineIcon(engine),
                    color: _getEngineColor(engine),
                  ),
                  title: Text(
                    _getEngineName(engine),
                    style: const TextStyle(fontSize: 17),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF007AFF),
                        )
                      : null,
                  onTap: () {
                    _searchBloc.add(SetEngineEvent(engine));
                    Navigator.pop(sheetContext);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _getEngineName(SearchEngine engine) {
    switch (engine) {
      case SearchEngine.google:
        return 'Google';
      case SearchEngine.bing:
        return 'Bing';
      case SearchEngine.duckduckgo:
        return 'DuckDuckGo';
      case SearchEngine.youtube:
        return 'YouTube';
      case SearchEngine.wikipedia:
        return 'Wikipedia';
      case SearchEngine.github:
        return 'GitHub';
    }
  }

  IconData _getEngineIcon(SearchEngine engine) {
    switch (engine) {
      case SearchEngine.google:
        return Icons.public;
      case SearchEngine.bing:
        return Icons.bubble_chart;
      case SearchEngine.duckduckgo:
        return Icons.shield;
      case SearchEngine.youtube:
        return Icons.play_circle_filled;
      case SearchEngine.wikipedia:
        return Icons.menu_book;
      case SearchEngine.github:
        return Icons.code;
    }
  }

  Color _getEngineColor(SearchEngine engine) {
    switch (engine) {
      case SearchEngine.google:
        return const Color(0xFF4285F4);
      case SearchEngine.bing:
        return const Color(0xFF008373);
      case SearchEngine.duckduckgo:
        return const Color(0xFFDE5833);
      case SearchEngine.youtube:
        return const Color(0xFFFF0000);
      case SearchEngine.wikipedia:
        return const Color(0xFF000000);
      case SearchEngine.github:
        return const Color(0xFF181717);
    }
  }
}