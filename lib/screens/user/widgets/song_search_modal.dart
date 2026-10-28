import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/song_sort_helper.dart';
import '../../../models/song_model.dart';

/// Modal pencarian lagu dengan field besar dan daftar hasil yang lebih jelas.
class SongSearchModal extends StatefulWidget {
  static const fieldKey = ValueKey('song_search_modal_field');
  static const sheetKey = ValueKey('song_search_modal_sheet');
  static const closeTooltip = 'Tutup Pencarian';

  final List<SongModel> songs;
  final List<SongModel> queue;
  final int? initialCategory;
  final bool isLoading;
  final ValueChanged<SongModel> onAddToQueue;

  const SongSearchModal({
    super.key,
    required this.songs,
    this.queue = const [],
    required this.onAddToQueue,
    this.initialCategory,
    this.isLoading = false,
  });

  static Future<void> show(
    BuildContext context, {
    required List<SongModel> songs,
    List<SongModel> queue = const [],
    required ValueChanged<SongModel> onAddToQueue,
    int? initialCategory,
    bool isLoading = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: SongSearchModal(
            songs: songs,
            queue: queue,
            initialCategory: initialCategory,
            isLoading: isLoading,
            onAddToQueue: onAddToQueue,
          ),
        );
      },
    );
  }

  @override
  State<SongSearchModal> createState() => _SongSearchModalState();
}

class _SongSearchModalState extends State<SongSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<int> _queuedSongIds;
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _queuedSongIds = widget.queue.map((song) => song.songid).toSet();
    _selectedCategory = widget.initialCategory;
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SongModel> get _filteredSongs {
    final query = _searchController.text.trim().toLowerCase();
    final matches = widget.songs.where((song) {
      final matchesQuery = query.isEmpty ||
          song.songtitle.toLowerCase().contains(query) ||
          song.songsinger.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == null ||
          song.songcategory == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
    sortSongsByNumber(matches);
    return matches;
  }

  void _addSong(SongModel song) {
    if (_queuedSongIds.contains(song.songid)) return;

    widget.onAddToQueue(song);
    setState(() {
      _queuedSongIds.add(song.songid);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${song.songtitle}" ditambahkan ke playlist'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryElectric,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSongs;
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final availableHeight = media.size.height - keyboardHeight;
    final modalHeight = availableHeight * 0.9;

    return Container(
      key: SongSearchModal.sheetKey,
      height: modalHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle & close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  tooltip: SongSearchModal.closeTooltip,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'Cari Lagu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Big search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 56,
              child: TextField(
                key: SongSearchModal.fieldKey,
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Ketik judul atau nomor lagu...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6FA4CE),
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.accentCyan,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${filtered.length} lagu ditemukan',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Results
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentCyan,
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tidak ada lagu yang cocok',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final song = filtered[index];
                          return _buildResultCard(
                            song,
                            _queuedSongIds.contains(song.songid),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SongModel song, bool isQueued) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isQueued ? null : () => _addSong(song),
      child: Container(
        key: ValueKey('song_search_modal_result_${song.songid}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF162235),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF24364F)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.songtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.songsinger,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8EA9C7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isQueued ? null : () => _addSong(song),
              tooltip: isQueued ? 'Sudah di Playlist' : 'Tambah ke Playlist',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                isQueued
                    ? Icons.check_circle_rounded
                    : Icons.playlist_add_rounded,
                color: isQueued
                    ? const Color(0xFF34D399)
                    : const Color(0xFF85B6DF),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
