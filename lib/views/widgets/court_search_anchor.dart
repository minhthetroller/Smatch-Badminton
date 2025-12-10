import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/search_suggestion.dart';
import '../../view_models/search_view_model.dart';

/// Google Maps style search bar that opens a full-screen search overlay
class CourtSearchAnchor extends StatelessWidget {
  final String hintText;
  final String? selectedCourtName;
  final void Function(SearchSuggestion suggestion)? onSuggestionSelected;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onClear;

  const CourtSearchAnchor({
    super.key,
    this.hintText = 'Search here',
    this.selectedCourtName,
    this.onSuggestionSelected,
    this.onVoiceSearch,
    this.onClear,
  });

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _SearchOverlayPage(
            hintText: hintText,
            onSuggestionSelected: onSuggestionSelected,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedCourt = selectedCourtName != null && selectedCourtName!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openSearchOverlay(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Leading logo
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: _GoogleMapsLogo(),
            ),

            // Display selected court name or hint text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hasSelectedCourt ? selectedCourtName! : hintText,
                  style: TextStyle(
                    fontSize: 16,
                    color: hasSelectedCourt ? AppTheme.textPrimary : AppTheme.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Voice search button when no court is selected
            if (!hasSelectedCourt && onVoiceSearch != null)
              IconButton(
                icon: const Icon(Icons.mic),
                color: AppTheme.textSecondary,
                onPressed: onVoiceSearch,
                tooltip: 'Voice search',
              ),

            // Clear button replaces avatar when court is selected
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: hasSelectedCourt
                  ? GestureDetector(
                      onTap: () {
                        // Clear selection when X button is pressed
                        onClear?.call();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : const _ProfileAvatar(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen search overlay page
class _SearchOverlayPage extends StatefulWidget {
  final String hintText;
  final void Function(SearchSuggestion suggestion)? onSuggestionSelected;

  const _SearchOverlayPage({
    required this.hintText,
    this.onSuggestionSelected,
  });

  @override
  State<_SearchOverlayPage> createState() => _SearchOverlayPageState();
}

class _SearchOverlayPageState extends State<_SearchOverlayPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    context.read<SearchViewModel>().searchAutocomplete(value);
  }

  void _closeSearch() {
    context.read<SearchViewModel>().clearSearch();
    Navigator.of(context).pop();
  }

  void _clearText() {
    _textController.clear();
    context.read<SearchViewModel>().clearSearch();
    _focusNode.requestFocus();
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    context.read<SearchViewModel>().clearSearch();
    Navigator.of(context).pop();
    widget.onSuggestionSelected?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar with same shape as the closed state
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildSearchBar(),
            ),

            // Suggestions list
            Expanded(
              child: _buildSuggestionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textSecondary,
            onPressed: _closeSearch,
          ),

          // Search text field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Clear button when text is not empty
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, child) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  color: AppTheme.textSecondary,
                  onPressed: _clearText,
                );
              }
              return const SizedBox(width: 8);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Consumer<SearchViewModel>(
      builder: (context, searchVM, _) {
        final suggestions = searchVM.autocompleteSuggestions;
        final isLoading = searchVM.isLoadingAutocomplete;
        final query = _textController.text;

        // Show loading indicator
        if (isLoading && suggestions.isEmpty && query.length >= 2) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Show empty state when no results
        if (query.length >= 2 && suggestions.isEmpty && !isLoading) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No results found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show hint when query is empty
        if (query.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for badminton courts',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        // Show suggestions list with scroll-to-dismiss keyboard
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Dismiss keyboard when user starts scrolling
            if (notification is ScrollStartNotification) {
              _focusNode.unfocus();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _SuggestionTile(
                suggestion: suggestion,
                onTap: () => _onSuggestionTap(suggestion),
              );
            },
          ),
        );
      },
    );
  }
}

/// Individual suggestion tile
class _SuggestionTile extends StatelessWidget {
  final SearchSuggestion suggestion;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.location_on_outlined,
          color: Colors.grey[600],
          size: 22,
        ),
      ),
      title: Text(
        suggestion.text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: suggestion.address != null && suggestion.address!.isNotEmpty
          ? Text(
              suggestion.address!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.north_west,
        size: 18,
        color: Colors.grey[400],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}

/// Google Maps style logo
class _GoogleMapsLogo extends StatelessWidget {
  const _GoogleMapsLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.location_on, color: Color(0xFF34A853), size: 24),
    );
  }
}

/// Profile avatar placeholder
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.person, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
}
