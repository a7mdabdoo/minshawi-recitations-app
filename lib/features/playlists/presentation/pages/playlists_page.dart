import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';
import '../../domain/entities/playlist.dart';
import '../cubit/playlists_cubit.dart';
import '../cubit/playlists_state.dart';
import 'playlist_detail_page.dart';

/// Standalone Playlists screen for viewing, searching, and managing custom collections.
class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'قوائم التشغيل المخصصة',
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: gold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: gold),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'رجوع',
        ),
      ),
      body: const PlaylistsContentView(showSearch: true),
    );
  }
}

/// The reusable content body displaying custom playlists with optional search.
class PlaylistsContentView extends StatefulWidget {
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final bool showSearch;

  const PlaylistsContentView({
    super.key,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.showSearch = true,
  });

  @override
  State<PlaylistsContentView> createState() => _PlaylistsContentViewState();
}

class _PlaylistsContentViewState extends State<PlaylistsContentView> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'إنشاء قائمة تشغيل جديدة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اسم القائمة (مثال: تلاوات مختارة)...',
              hintStyle: GoogleFonts.cairo(color: textSecondary, fontSize: 13),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withAlpha(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: gold.withAlpha(isDark ? 80 : 50),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: gold, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                    isDark ? AppColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogCtx).pop();
                  await context.read<PlaylistsCubit>().createPlaylist(name);
                }
              },
              child: Text(
                'إنشاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String playlistId,
    String playlistTitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'حذف قائمة التشغيل؟',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          content: Text(
            'هل ترغب في حذف قائمة التشغيل $playlistTitle نهائياً؟',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await context.read<PlaylistsCubit>().deletePlaylist(playlistId);
              },
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    Color gold,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? gold.withAlpha(isDark ? 160 : 120)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: _searchQuery.isNotEmpty ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(color: textPrimary, fontSize: 13.5),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'البحث في قوائم التشغيل أو السور...',
          hintStyle: GoogleFonts.cairo(color: textSecondary, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchQuery.isNotEmpty ? gold : textSecondary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  tooltip: 'مسح البحث',
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        if (state is PlaylistsLoading || state is PlaylistsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PlaylistsError) {
          return _PlaylistsErrorView(
            message: state.message,
            isDark: isDark,
            gold: gold,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onRetry: () => context.read<PlaylistsCubit>().loadPlaylists(),
          );
        }

        if (state is PlaylistsEmpty) {
          return _EmptyPlaylistsView(
            isDark: isDark,
            gold: gold,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            padding: widget.padding,
            onCreate: () => _showCreateDialog(context),
          );
        }

        if (state is PlaylistsLoaded) {
          final playlists = state.playlists;

          if (playlists.isEmpty) {
            return _EmptyPlaylistsView(
              isDark: isDark,
              gold: gold,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              padding: widget.padding,
              onCreate: () => _showCreateDialog(context),
            );
          }

          return BlocBuilder<RecitationListCubit, RecitationListState>(
            builder: (context, recitationListState) {
              final allRecitations =
                  recitationListState is RecitationListLoaded
                      ? recitationListState.recitations
                      : <Recitation>[];
              final recitationsMap = {for (var r in allRecitations) r.id: r};

              final cleanQuery = _searchQuery.trim().toLowerCase();
              final cleanQueryNorm = ArabicNormalizer.normalize(cleanQuery);

              final filteredPlaylists = playlists.where((playlist) {
                if (cleanQuery.isEmpty) return true;

                final pName = (playlist.name.isNotEmpty
                        ? playlist.name
                        : playlist.title)
                    .toLowerCase();
                final pNameNorm = ArabicNormalizer.normalize(pName);
                final pDesc = playlist.description.toLowerCase();
                final pDescNorm = ArabicNormalizer.normalize(pDesc);

                final matchesName = pName.contains(cleanQuery) ||
                    pNameNorm.contains(cleanQueryNorm) ||
                    pDesc.contains(cleanQuery) ||
                    pDescNorm.contains(cleanQueryNorm);

                if (matchesName) return true;

                final playlistRecs = playlist.recitations.isNotEmpty
                    ? playlist.recitations
                    : playlist.recitationIds
                        .map((id) => recitationsMap[id])
                        .whereType<Recitation>()
                        .toList();

                final matchesRecitation = playlistRecs.any((r) {
                  final arName = r.surahNameAr.toLowerCase();
                  final arNorm = ArabicNormalizer.normalize(arName);
                  final enName = r.surahNameEn.toLowerCase();

                  return arName.contains(cleanQuery) ||
                      arNorm.contains(cleanQueryNorm) ||
                      enName.contains(cleanQuery);
                });

                return matchesRecitation;
              }).toList();

              if (filteredPlaylists.isEmpty) {
                final noResultsWidget = _NoSearchResultsView(
                  query: _searchQuery,
                  isDark: isDark,
                  gold: gold,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                );

                return Column(
                  mainAxisSize:
                      widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    if (widget.showSearch)
                      _buildSearchBar(
                        isDark,
                        gold,
                        cardBg,
                        textPrimary,
                        textSecondary,
                      ),
                    if (widget.shrinkWrap)
                      noResultsWidget
                    else
                      Expanded(child: noResultsWidget),
                  ],
                );
              }

              final listView = ListView.separated(
                physics: widget.physics,
                shrinkWrap: widget.shrinkWrap,
                padding: widget.padding ??
                    const EdgeInsets.fromLTRB(16, 8, 16, 96),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: filteredPlaylists.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showCreateDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withAlpha(isDark ? 25 : 15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gold.withAlpha(isDark ? 90 : 60),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'إنشاء قائمة تشغيل جديدة',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final playlist = filteredPlaylists[index - 1];
                  final effectiveRecitations = playlist.recitations.isNotEmpty
                      ? playlist.recitations
                      : playlist.recitationIds
                          .map((id) => recitationsMap[id])
                          .whereType<Recitation>()
                          .toList();

                  final recitationsCount = playlist.recitations.isNotEmpty
                      ? playlist.recitations.length
                      : playlist.recitationIds.length;

                  return RepaintBoundary(
                    child: _PlaylistOverviewCard(
                      playlist: playlist,
                      recitationsCount: recitationsCount,
                      isDark: isDark,
                      gold: gold,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaylistDetailPage(
                              playlistId: playlist.id,
                            ),
                          ),
                        );
                      },
                      onPlay: () {
                        if (effectiveRecitations.isNotEmpty) {
                          context.read<AudioPlayerCubit>().play(
                                effectiveRecitations.first,
                                playlist: effectiveRecitations,
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'قائمة التشغيل فارغة! أضف تلاوات أولاً.',
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      onDelete: () => _showDeleteDialog(
                        context,
                        playlist.id,
                        playlist.title,
                      ),
                    ),
                  );
                },
              );

              if (!widget.showSearch) {
                return listView;
              }

              return Column(
                mainAxisSize:
                    widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  _buildSearchBar(
                    isDark,
                    gold,
                    cardBg,
                    textPrimary,
                    textSecondary,
                  ),
                  if (widget.shrinkWrap)
                    listView
                  else
                    Expanded(child: listView),
                ],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PlaylistOverviewCard extends StatelessWidget {
  final Playlist playlist;
  final int recitationsCount;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _PlaylistOverviewCard({
    required this.playlist,
    required this.recitationsCount,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final dateStr =
        '${playlist.createdAt.year}/${playlist.createdAt.month.toString().padLeft(2, '0')}/${playlist.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title.isNotEmpty
                            ? playlist.title
                            : 'قائمة جديدة',
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      if (playlist.description.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          playlist.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: textSecondary.withAlpha(190),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '$recitationsCount تلاوة  ·  تم الإنشاء: $dateStr',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 36,
                    color: gold,
                  ),
                  onPressed: onPlay,
                  tooltip: 'تشغيل القائمة كاملة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: textSecondary,
                  ),
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'open') onTap();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 18, color: gold),
                          const SizedBox(width: 10),
                          Text('فتح القائمة',
                              style: GoogleFonts.cairo(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.darkError),
                          const SizedBox(width: 10),
                          Text(
                            'حذف القائمة',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: AppColors.darkError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlaylistsView extends StatelessWidget {
  final bool isDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final EdgeInsetsGeometry? padding;
  final VoidCallback onCreate;

  const _EmptyPlaylistsView({
    required this.isDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    this.padding,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: gold.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 38,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد قوائم تشغيل مخصصة',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ قوائم تشغيل لتنظيم تلاواتك المفضلة والاستماع إليها متتالية.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                    isDark ? AppColors.darkBackground : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'إنشاء قائمة جديدة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsView extends StatelessWidget {
  final String query;
  final bool isDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onClear;

  const _NoSearchResultsView({
    required this.query,
    required this.isDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: gold.withAlpha(isDark ? 25 : 15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: gold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'لم يتم العثور على نتائج',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد قائمة تشغيل أو سورة تطابق "$query"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                    isDark ? AppColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: Text(
                'مسح البحث',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistsErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onRetry;

  const _PlaylistsErrorView({
    required this.message,
    required this.isDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.darkError.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.darkError,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'تعذر تحميل قوائم التشغيل',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty
                  ? message
                  : 'حدث خطأ غير متوقع أثناء تحميل البيانات.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                    isDark ? AppColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
