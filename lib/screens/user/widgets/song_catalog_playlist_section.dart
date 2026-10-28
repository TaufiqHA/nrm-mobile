import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/song_sort_helper.dart';
import '../../../models/category_model.dart';
import '../../../models/song_model.dart';

class SongCatalogPlaylistSection extends StatefulWidget {
  final List<SongModel> songs;
  final List<CategoryModel> categories;
  final List<SongModel> queue;
  final SongModel? currentPlayingSong;
  final bool isLoading;
  final ValueChanged<SongModel> onPlaySong;
  final ValueChanged<SongModel> onAddToQueue;
  final ValueChanged<int>? onRemoveFromQueue;
  final Function(int oldIndex, int newIndex)? onReorderQueue;
  final VoidCallback? onClearQueue;
  final Future<void> Function()? onRefresh;
  final Axis axis;
  final int? initialCategory;
  final VoidCallback? onOpenSearchModal;

  const SongCatalogPlaylistSection({
    super.key,
    required this.songs,
    required this.categories,
    required this.queue,
    required this.currentPlayingSong,
    this.isLoading = false,
    required this.onPlaySong,
    required this.onAddToQueue,
    this.onRemoveFromQueue,
    this.onReorderQueue,
    this.onClearQueue,
    this.onRefresh,
    this.axis = Axis.horizontal,
    this.initialCategory,
    this.onOpenSearchModal,
  });

  @override
  State<SongCatalogPlaylistSection> createState() => _SongCatalogPlaylistSectionState();
}

class _SongCatalogPlaylistSectionState extends State<SongCatalogPlaylistSection> {
  int? _selectedCategory;
  int _compactTabIndex = 0; // 0 = Cari Lagu, 1 = Playlist

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  List<SongModel> get _filteredSongs {
    final matches = widget.songs.where((song) {
      return _selectedCategory == null ||
          song.songcategory == _selectedCategory;
    }).toList();
    sortSongsByNumber(matches);
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    const filterPanelBg = Color(0xFF537699); // Blue-grey slate from reference design
    const cardBg = Color(0xFF162235); // Dark blue navy card
    const cardBorder = Color(0xFF24364F); // Border card

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactVertical =
            widget.axis == Axis.vertical && constraints.maxHeight < 500;

        if (isCompactVertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact Segmented Tab Bar (Cari Lagu vs Playlist)
                _buildCompactTabBar(),
                // Tab Content
                Expanded(
                  child: _compactTabIndex == 0
                      ? _buildSearchSection(
                          context,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                        )
                      : _buildPlaylistSection(
                          context,
                          filterPanelBg: filterPanelBg,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          hideHeaderTab: true,
                        ),
                ),
              ],
            ),
          );
        }

        if (widget.axis == Axis.vertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top section: Cari Lagu & Hasil Pencarian
                Expanded(
                  flex: 5,
                  child: _buildSearchSection(
                    context,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ),
                const SizedBox(height: 10),
                // Bottom section: Playlist
                Expanded(
                  flex: 4,
                  child: _buildPlaylistSection(
                    context,
                    filterPanelBg: filterPanelBg,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= LEFT COLUMN: CARI LAGU & HASIL PENCARIAN =================
              Expanded(
                child: _buildSearchSection(
                  context,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 10),
              // ================= RIGHT COLUMN: PLAYLIST =================
              Expanded(
                child: _buildPlaylistSection(
                  context,
                  filterPanelBg: filterPanelBg,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(
    BuildContext context, {
    required Color cardBg,
    required Color cardBorder,
  }) {
    final filteredSongs = _filteredSongs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Bar (tap untuk membuka modal pencarian besar)
        InkWell(
          onTap: widget.onOpenSearchModal,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CC7EA),
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Cari lagu...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Section Title: Hasil Pencarian
        const Padding(
          padding: EdgeInsets.only(left: 2.0, bottom: 6.0),
          child: Text(
            'daftar lagu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF98B8DA),
            ),
          ),
        ),

        // 4. Hasil Pencarian Cards (Scrollable Area)
        Expanded(
          child: widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                    strokeWidth: 2,
                  ),
                )
              : filteredSongs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada lagu yang cocok',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: filteredSongs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        final isCurrent = widget.currentPlayingSong?.songid == song.songid;

                        return _buildSearchResultCard(
                          song: song,
                          isCurrent: isCurrent,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCompactTabBar() {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF24364F)),
      ),
      child: Row(
        children: [
          // Tab Cari Lagu
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _compactTabIndex = 0),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _compactTabIndex == 0
                      ? AppColors.primaryElectric.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: _compactTabIndex == 0
                      ? Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 13,
                      color: _compactTabIndex == 0
                          ? AppColors.accentCyan
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cari Lagu',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _compactTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _compactTabIndex == 0
                            ? AppColors.accentCyan
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Playlist
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _compactTabIndex = 1),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _compactTabIndex == 1
                      ? AppColors.primaryElectric.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: _compactTabIndex == 1
                      ? Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      size: 13,
                      color: _compactTabIndex == 1
                          ? AppColors.accentCyan
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Playlist',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _compactTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _compactTabIndex == 1
                            ? AppColors.accentCyan
                            : AppColors.textMuted,
                      ),
                    ),
                    if (widget.queue.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.queue.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSection(
    BuildContext context, {
    required Color filterPanelBg,
    required Color cardBg,
    required Color cardBorder,
    bool hideHeaderTab = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tab / Button Header: "playlist" (hanya jika tidak menggunakan tab atas)
        if (!hideHeaderTab) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: filterPanelBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF6B8FB5)),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'playlist',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 2. Playlist Container (Scrollable inside)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: filterPanelBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF6B8FB5)),
            ),
            child: widget.queue.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 26,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Playlist masih kosong',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tekan ikon (+) pada lagu untuk menambahkan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 6),
                    buildDefaultDragHandles: false,
                    itemCount: widget.queue.length,
                    onReorder: (oldIndex, newIndex) {
                      if (widget.onReorderQueue != null) {
                        widget.onReorderQueue!(oldIndex, newIndex);
                      }
                    },
                    itemBuilder: (context, index) {
                      final song = widget.queue[index];

                      return Padding(
                        key: ValueKey('queue_${song.songid}_$index'),
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: ReorderableDelayedDragStartListener(
                          index: index,
                          child: Dismissible(
                            key: ValueKey('dismiss_queue_${song.songid}_$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            onDismissed: (_) {
                              widget.onRemoveFromQueue?.call(index);
                            },
                            child: _buildPlaylistCard(
                              song: song,
                              index: index,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Kartu Lagu di Kolom Hasil Pencarian (Kiri)
  Widget _buildSearchResultCard({
    required SongModel song,
    required bool isCurrent,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final isQueued = widget.queue.any((queued) => queued.songid == song.songid);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: isQueued
          ? null
          : () {
              widget.onAddToQueue(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${song.songtitle}" ditambahkan ke playlist'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryElectric,
                ),
              );
            },
      child: Container(
        key: ValueKey('search_song_card_${song.songid}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? AppColors.accentCyan : cardBorder,
            width: isCurrent ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Info Lagu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.songtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? AppColors.accentCyan : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    song.songsinger,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8EA9C7),
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Tambah ke Playlist
            IconButton(
              onPressed: isQueued
                  ? null
                  : () {
                      widget.onAddToQueue(song);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${song.songtitle}" ditambahkan ke playlist'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primaryElectric,
                        ),
                      );
                    },
              tooltip: isQueued ? 'Sudah di Playlist' : 'Tambah ke Playlist',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isQueued
                    ? Icons.check_circle_rounded
                    : Icons.playlist_add_rounded,
                color: isQueued
                    ? const Color(0xFF34D399)
                    : const Color(0xFF85B6DF),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Lagu di Kolom Playlist (Kanan) - Ringkas, tinggi sama dengan hasil pencarian.
  Widget _buildPlaylistCard({
    required SongModel song,
    required int index,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      key: ValueKey('playlist_song_card_${song.songid}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Info Lagu
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  song.songsinger,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8EA9C7),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Putar
          IconButton(
            onPressed: () {
              widget.onPlaySong(song);
              widget.onRemoveFromQueue?.call(index);
            },
            tooltip: 'Putar Lagu',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF85B6DF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
