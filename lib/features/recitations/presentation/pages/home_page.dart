import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/cubit/audio_player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../domain/entities/recitation.dart';
import '../cubit/download_cubit.dart';
import '../cubit/download_state.dart';
import '../cubit/recitation_list_cubit.dart';
import '../cubit/recitation_list_state.dart';

class HomePage extends StatelessWidget {
  final String collectionId;
  const HomePage({super.key, this.collectionId = 'rare_1387'});

  @override
  Widget build(BuildContext context) {
    context
        .read<RecitationListCubit>()
        .loadRecitations(collectionId: collectionId);
    return _HomeView(collectionId: collectionId);
  }
}

enum _ListTab { all, favorites }

class _HomeView extends StatefulWidget {
  final String collectionId;
  const _HomeView({required this.collectionId});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  _ListTab _selectedTab = _ListTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      context.read<AudioPlayerCubit>().saveCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<RecitationListCubit, RecitationListState>(
          listener: (context, state) {
            if (state is RecitationListLoaded) {
              context
                  .read<AudioPlayerCubit>()
                  .updatePlaylist(state.recitations);
            }
          },
        ),
        BlocListener<AudioPlayerCubit, AudioPlayerState>(
          listenWhen: (prev, curr) => curr is AudioPlayerError,
          listener: (context, state) {
            if (state is AudioPlayerError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.goldPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    96.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.goldPrimary.withAlpha(160),
                      width: 1.2,
                    ),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
        BlocListener<DownloadCubit, DownloadState>(
          listenWhen: (prev, curr) =>
              curr.lastError != null && prev.lastError != curr.lastError,
          listener: (context, state) {
            if (state.lastError != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        state.lastError!.contains('مساحة')
                            ? Icons.sd_card_alert_rounded
                            : Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.lastError!,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    96.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.darkError.withAlpha(180),
                      width: 1.2,
                    ),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        bottomNavigationBar: const MiniPlayer(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _AppBar(
              isDark: isDark,
              collectionId: widget.collectionId,
            ),
            _FilterTabs(
              selectedTab: _selectedTab,
              isDark: isDark,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
            ),
            _SearchBar(isDark: isDark),
            _ResumePlaybackBanner(isDark: isDark),
            _Body(
              isDark: isDark,
              selectedTab: _selectedTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final bool isDark;
  final String collectionId;
  const _AppBar({required this.isDark, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final title = switch (collectionId) {
      'mojawad' => 'المصحف المجود',
      'complete_murattal' => 'المصحف المرتل كاملاً',
      _ => 'تسجيلات 1387 هـ النادرة',
    };
    final subtitle = switch (collectionId) {
      'mojawad' => 'الشيخ محمد صديق المنشاوي (١١٤ سورة)',
      'complete_murattal' => 'الشيخ محمد صديق المنشاوي (١١٤ سورة)',
      _ => 'الشيخ محمد صديق المنشاوي (٢٦ سورة)',
    };

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
        ),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        tooltip: 'الرئيسية',
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.queue_music_rounded,
            color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
          ),
          onPressed: () => context.push(AppRoutes.playlists),
          tooltip: 'قوائم التشغيل',
        ),
        IconButton(
          icon: Icon(
            Icons.folder_special_outlined,
            color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
          ),
          onPressed: () => context.push(AppRoutes.downloads),
          tooltip: 'التلاوات المحمّلة',
        ),
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
          ),
          onPressed: () => context.read<ThemeCubit>().toggle(),
          tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(right: 56, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.amiri(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        background: _AppBarBackground(isDark: isDark),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  final bool isDark;
  const _AppBarBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [AppColors.darkCardSurface, AppColors.darkBackground]
              : [AppColors.lightCardSurface, AppColors.lightBackground],
        ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 50),
          child: Text(
            '﷽',
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: isDark
                  ? AppColors.goldPrimary.withAlpha(60)
                  : AppColors.goldDark.withAlpha(40),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _ListTab selectedTab;
  final bool isDark;
  final ValueChanged<_ListTab> onTabSelected;

  const _FilterTabs({
    required this.selectedTab,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.list_alt_rounded,
                label: 'التلاوات',
                isSelected: selectedTab == _ListTab.all,
                gold: gold,
                bg: bg,
                isDark: isDark,
                onTap: () => onTabSelected(_ListTab.all),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, favState) {
                  final count = favState.favoriteIds.length;
                  return _TabButton(
                    icon: Icons.favorite_rounded,
                    label: count > 0 ? 'المفضلة ($count)' : 'المفضلة',
                    isSelected: selectedTab == _ListTab.favorites,
                    gold: gold,
                    bg: bg,
                    isDark: isDark,
                    onTap: () => onTabSelected(_ListTab.favorites),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color gold;
  final Color bg;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.gold,
    required this.bg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? gold : bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? gold
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gold.withAlpha(isDark ? 70 : 40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? (isDark ? AppColors.darkBackground : Colors.white)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? AppColors.darkBackground : Colors.white)
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final bool isDark;
  const _SearchBar({required this.isDark});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          controller: _controller,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن سورة بالاسم أو الرقم...',
            hintStyle: GoogleFonts.cairo(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color:
                  isDark ? AppColors.darkIconColor : AppColors.lightIconColor,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      size: 18,
                    ),
                    onPressed: () {
                      _controller.clear();
                      context.read<RecitationListCubit>().search('');
                      setState(() {});
                    },
                    tooltip: 'مسح البحث',
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkCardSurface
                : AppColors.lightCardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (q) {
            context.read<RecitationListCubit>().search(q);
            setState(() {});
          },
        ),
      ),
    );
  }
}

class _ResumePlaybackBanner extends StatefulWidget {
  final bool isDark;
  const _ResumePlaybackBanner({required this.isDark});

  @override
  State<_ResumePlaybackBanner> createState() => _ResumePlaybackBannerState();
}

class _ResumePlaybackBannerState extends State<_ResumePlaybackBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (previous, current) =>
          (previous is AudioPlayerIdle) != (current is AudioPlayerIdle),
      builder: (context, playerState) {
        // Hide banner if audio player is already active / loaded
        if (playerState is! AudioPlayerIdle) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final lastId = settingsState.lastPlayedRecitationId;
            final lastSeconds = settingsState.lastPlayedPositionSeconds ?? 0;

            // Only show if there is a saved track with at least 5 seconds of playback
            if (lastId == null || lastSeconds < 5) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return BlocBuilder<RecitationListCubit, RecitationListState>(
              builder: (context, listState) {
                if (listState is! RecitationListLoaded) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                Recitation? found;
                try {
                  found = listState.recitations.firstWhere(
                    (r) => r.id == lastId,
                  );
                } catch (_) {
                  found = null;
                }

                if (found == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final recitation = found;

                final isDark = widget.isDark;
                final gold =
                    isDark ? AppColors.goldPrimary : AppColors.goldDark;
                final bg = isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9);
                final textPrimary = isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary;
                final textSecondary = isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary;

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: gold.withAlpha(isDark ? 90 : 60),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 50 : 15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: gold.withAlpha(isDark ? 40 : 30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: gold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'استئناف الاستماع من حيث توقفت',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'سورة ${recitation.surahNameAr} · عند ${Formatters.formatDuration(lastSeconds)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(
                              'استئناف',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () {
                              context.read<AudioPlayerCubit>().play(
                                    recitation,
                                    initialPosition:
                                        Duration(seconds: lastSeconds),
                                    playlist: listState.recitations,
                                  );
                            },
                          ),
                          const SizedBox(width: 6),

                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'إغلاق',
                            onPressed: () {
                              setState(() => _dismissed = true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final bool isDark;
  final _ListTab selectedTab;
  const _Body({required this.isDark, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecitationListCubit, RecitationListState>(
      builder: (context, state) {
        if (state is RecitationListLoading || state is RecitationListInitial) {
          return const SliverFillRemaining(child: _LoadingView());
        }

        if (state is RecitationListError) {
          return SliverFillRemaining(
            child: _ErrorView(message: state.message, isDark: isDark),
          );
        }

        if (state is RecitationListLoaded) {
          var items = state.filtered;

          // Filter by favorites tab if selected
          if (selectedTab == _ListTab.favorites) {
            final favoritesState = context.watch<FavoritesCubit>().state;
            items = items
                .where((r) => favoritesState.isFavorite(r.id))
                .toList();

            if (items.isEmpty) {
              return SliverFillRemaining(
                child: _FavoritesEmptyView(isDark: isDark),
              );
            }
          }

          if (items.isEmpty) {
            return SliverFillRemaining(
              child: _EmptyView(isDark: isDark),
            );
          }
          return _RecitationList(items: items, isDark: isDark);
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            'جارٍ تحميل التلاوات...',
            style: GoogleFonts.cairo(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorView({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: isDark ? AppColors.darkError : AppColors.lightError,
            ),
            const SizedBox(height: 20),
            Text(
              'تعذّر تحميل التلاوات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<RecitationListCubit>().refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isDark;
  const _EmptyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج مطابقة للبحث',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesEmptyView extends StatelessWidget {
  final bool isDark;
  const _FavoritesEmptyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;

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
                shape: BoxShape.circle,
                color: gold.withAlpha(25),
                border: Border.all(color: gold.withAlpha(80), width: 1.5),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'قائمة المفضلة فارغة',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'انقر على أيقونة القلب في بطاقة أي سورة لإضافتها إلى قائمة مفضلتك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecitationList extends StatelessWidget {
  final List<Recitation> items;
  final bool isDark;
  const _RecitationList({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    context.read<AudioPlayerCubit>().updatePlaylist(items);
    final bottomInset = 120.0 + MediaQuery.of(context).padding.bottom;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
      sliver: SliverList.separated(
        itemCount: items.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => RepaintBoundary(
          child: _RecitationCard(recitation: items[index], isDark: isDark),
        ),
      ),
    );
  }
}

class _RecitationCard extends StatelessWidget {
  final Recitation recitation;
  final bool isDark;
  const _RecitationCard({required this.recitation, required this.isDark});

  void _showDeleteDialog(BuildContext context, DownloadCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف التلاوة المحمّلة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'هل تريد حذف تلاوة سورة ${recitation.surahNameAr} من التخزين المحلي؟',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.deleteDownload(recitation);
            },
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = recitation;

    // Watch only the current recitation field to highlight the active card.
    final isActive = context.select<AudioPlayerCubit, bool>((cubit) {
      final s = cubit.state;
      if (s is AudioPlayerReady) return s.recitation.id == r.id;
      if (s is AudioPlayerLoading) return s.recitation.id == r.id;
      return false;
    });

    final activeGold = isDark ? AppColors.goldPrimary : AppColors.goldDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                ? AppColors.goldPrimary.withAlpha(18)
                : AppColors.goldDark.withAlpha(12))
            : (isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? activeGold.withAlpha(160)
              : r.isDownloaded
                  ? AppColors.downloadedColor.withAlpha(90)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final playerCubit = context.read<AudioPlayerCubit>();
            final s = playerCubit.state;
            if (s is AudioPlayerReady && s.recitation.id == r.id) {
              playerCubit.togglePlayPause();
            } else {
              playerCubit.play(r);
            }
          },
          onLongPress: r.isDownloaded
              ? () => _showDeleteDialog(context, context.read<DownloadCubit>())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _SurahBadge(
                  number: r.surahNumber,
                  isActive: isActive,
                  isDark: isDark,
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.surahNameAr,
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? activeGold
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r.isDownloaded) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.offline_pin_rounded,
                              size: 15,
                              color: AppColors.downloadedColor.withAlpha(200),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.surahNameEn}  ·  الآيات: ${r.verseRange}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.durationSeconds > 0) ...[
                            Flexible(
                              child: _MetaChip(
                                icon: Icons.access_time_rounded,
                                label: Formatters.formatDuration(r.durationSeconds),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: _MetaChip(
                              icon: Icons.history_rounded,
                              label: r.recordingYear.contains('/')
                                  ? r.recordingYear.split('/')[0].trim()
                                  : r.recordingYear,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                _CardActionButtons(
                  recitation: r,
                  isActive: isActive,
                  isDark: isDark,
                  onDeleteRequested: () =>
                      _showDeleteDialog(context, context.read<DownloadCubit>()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahBadge extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isDark;
  const _SurahBadge({
    required this.number,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [AppColors.goldPrimary, AppColors.goldLight]
              : isDark
                  ? [AppColors.goldDark, AppColors.goldPrimary.withAlpha(180)]
                  : [AppColors.goldPrimary, AppColors.goldDark],
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.goldPrimary.withAlpha(100),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBackground,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CardActionButtons extends StatelessWidget {
  final Recitation recitation;
  final bool isActive;
  final bool isDark;
  final VoidCallback onDeleteRequested;

  const _CardActionButtons({
    required this.recitation,
    required this.isActive,
    required this.isDark,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final secondaryIconColor =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favState) {
              final isFav = favState.isFavorite(recitation.id);
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: secondaryIconColor,
                ),
                color: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
                tooltip: 'خيارات التلاوة',
                onSelected: (val) {
                  if (val == 'playlist') {
                    AddToPlaylistBottomSheet.show(context, recitation);
                  } else if (val == 'favorite') {
                    context
                        .read<FavoritesCubit>()
                        .toggleFavorite(recitation.id);
                  } else if (val == 'delete') {
                    onDeleteRequested();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add_rounded,
                            color: gold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'إضافة إلى قائمة تشغيل',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? const Color(0xFFEF4444)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isFav ? const Color(0xFFEF4444) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recitation.isDownloaded)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.darkError,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'حذف من الهاتف',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkError,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 2),

          BlocBuilder<DownloadCubit, DownloadState>(
            buildWhen: (prev, curr) {
              return prev.isDownloading(recitation.id) !=
                      curr.isDownloading(recitation.id) ||
                  prev.isPaused(recitation.id) !=
                      curr.isPaused(recitation.id) ||
                  prev.getProgress(recitation.id) !=
                      curr.getProgress(recitation.id);
            },
            builder: (context, downloadState) {
              final isDownloading = downloadState.isDownloading(recitation.id);
              final isPaused = downloadState.isPaused(recitation.id);
              final progress = downloadState.getProgress(recitation.id);
              final percent = (progress * 100).toInt();

              // State 1: Downloading (Pause icon inside CircularProgressIndicator)
              if (isDownloading) {
                return Tooltip(
                  message: 'إيقاف مؤقت ($percent%) · اضغط مطولاً للإلغاء',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context
                          .read<DownloadCubit>()
                          .pauseDownload(recitation.id);
                    },
                    onLongPress: () {
                      context
                          .read<DownloadCubit>()
                          .cancelDownload(recitation);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إلغاء التحميل',
                            style: GoogleFonts.cairo(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 2.4,
                              backgroundColor: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              color: gold,
                            ),
                            Icon(
                              Icons.pause_rounded,
                              size: 15,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // State 2: Paused (Single white circular ring with solid white play triangle)
              if (isPaused) {
                return Tooltip(
                  message: 'استئناف التنزيل ($percent%) · اضغط مطولاً للإلغاء',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context
                          .read<DownloadCubit>()
                          .resumeDownload(recitation);
                    },
                    onLongPress: () {
                      context
                          .read<DownloadCubit>()
                          .cancelDownload(recitation);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إلغاء التحميل',
                            style: GoogleFonts.cairo(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 2.4,
                              backgroundColor: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              color: Colors.white,
                            ),
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // State 3: Downloaded (Offline pin icon)
              if (recitation.isDownloaded) {
                return IconButton(
                  icon: const Icon(
                    Icons.offline_pin_rounded,
                    size: 20,
                  ),
                  color: AppColors.downloadedColor.withAlpha(220),
                  onPressed: onDeleteRequested,
                  tooltip: 'تم التحميل (اضغط للحذف)',
                  padding: const EdgeInsets.all(2),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                );
              }

              // State 4: Not Downloaded (Cloud download icon)
              return IconButton(
                icon: const Icon(
                  Icons.cloud_download_outlined,
                  size: 22,
                ),
                color: AppColors.availableColor,
                onPressed: () {
                  context.read<DownloadCubit>().startDownload(recitation);
                },
                tooltip: 'تحميل للاستماع بدون إنترنت',
                padding: const EdgeInsets.all(2),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              );
            },
          ),

          const SizedBox(width: 2),

          BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
            buildWhen: (prev, curr) {
              final prevActive = (prev is AudioPlayerReady &&
                      prev.recitation.id == recitation.id) ||
                  (prev is AudioPlayerLoading &&
                      prev.recitation.id == recitation.id);
              final currActive = (curr is AudioPlayerReady &&
                      curr.recitation.id == recitation.id) ||
                  (curr is AudioPlayerLoading &&
                      curr.recitation.id == recitation.id);
              final prevPlaying =
                  prev is AudioPlayerReady && prev.isPlaying;
              final currPlaying =
                  curr is AudioPlayerReady && curr.isPlaying;
              return prevActive != currActive ||
                  prevPlaying != currPlaying ||
                  (prev is AudioPlayerLoading) != (curr is AudioPlayerLoading);
            },
            builder: (context, playerState) {
              final isThisActive = (playerState is AudioPlayerReady &&
                      playerState.recitation.id == recitation.id) ||
                  (playerState is AudioPlayerLoading &&
                      playerState.recitation.id == recitation.id);

              final isThisPlaying = isThisActive &&
                  playerState is AudioPlayerReady &&
                  playerState.isPlaying;

              final isThisLoading = isThisActive &&
                  playerState is AudioPlayerLoading;

              if (isThisLoading) {
                return SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: gold,
                    ),
                  ),
                );
              }

              return IconButton(
                icon: Icon(
                  isThisPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 34,
                ),
                color: isThisActive ? gold : gold.withAlpha(210),
                onPressed: () {
                  final cubit = context.read<AudioPlayerCubit>();
                  if (isThisActive && playerState is AudioPlayerReady) {
                    cubit.togglePlayPause();
                  } else {
                    cubit.play(recitation);
                  }
                },
                tooltip: isThisPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                padding: const EdgeInsets.all(2),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              );
            },
          ),
        ],
      ),
    );
  }
}
