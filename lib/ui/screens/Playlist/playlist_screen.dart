// ignore_for_file: deprecated_member_use

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/models/playling_from.dart';
import '/models/thumbnail.dart';
import '../../../services/downloader.dart';
import '../../navigator.dart';
import '../../player/player_controller.dart';
import '../../widgets/loader.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/sort_widget.dart';
import '../Library/library_controller.dart';
import 'playlist_screen_controller.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final playlistController =
        (Get.isRegistered<PlaylistScreenController>(tag: tag))
            ? Get.find<PlaylistScreenController>(tag: tag)
            : Get.put(PlaylistScreenController(), tag: tag);
    final playerController = Get.find<PlayerController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Usamos CustomScrollView para efectos de scroll avanzados
      body: Obx(
        () => !playlistController.isContentFetched.isTrue
            ? const Center(
                child: LoadingIndicator()) // Muestra loader si no hay contenido
            : CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 12, bottom: 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 26),
                            tooltip: "Volver",
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    expandedHeight: 240,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final double top = constraints.maxHeight;
                        final bool collapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
                        return FlexibleSpaceBar(
                          centerTitle: false,
                          titlePadding: const EdgeInsetsDirectional.only(start: 5, bottom: 12, end: 16),
                          title: collapsed
                              ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 26),
                                      tooltip: "Volver",
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        playlistController.playlist.value.title,
                                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          background: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 0, top: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Carátula
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: Thumbnail(playlistController.playlist.value.thumbnailUrl).extraHigh,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[300],
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[400],
                                        child: const Icon(Icons.music_note, size: 64),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Info de la playlist
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [

                                      const SizedBox(height: 8),
                                      
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Text(
                                          playlistController.playlist.value.title,
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: textTheme.bodyLarge?.color,
                                            letterSpacing: -0.5,
                                            fontSize: 50
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          playlistController.playlist.value.description ?? "playlist".tr,
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: textTheme.bodyLarge?.color?.withOpacity(0.65),
                                            fontWeight: FontWeight.w400,
                                            fontSize: 24
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(height: 45),

                                      // Botonera única de acciones de la playlist
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            // Bookmark button
                                            if (!(playlistController.playlist.value.isPipedPlaylist ||
                                                !playlistController.playlist.value.isCloudPlaylist))
                                              IconButton(
                                                splashRadius: 10,
                                                onPressed: () {
                                                  final add = playlistController.isAddedToLibrary.isFalse;
                                                  playlistController
                                                      .addNremoveFromLibrary(
                                                          playlistController.playlist.value,
                                                          add: add)
                                                      .then((value) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(context).showSnackBar(snackbar(
                                                        context,
                                                        value
                                                            ? add
                                                                ? "playlistBookmarkAddAlert".tr
                                                                : "playlistBookmarkRemoveAlert".tr
                                                            : "operationFailed".tr,
                                                        size: SanckBarSize.MEDIUM));
                                                  });
                                                },
                                                icon: Icon(
                                                  playlistController.isAddedToLibrary.isFalse
                                                      ? Icons.bookmark_add
                                                      : Icons.bookmark_added,
                                                ),
                                              ),
                                            // Play button
                                            IconButton(
                                              onPressed: () {
                                                playerController.playPlayListSong(
                                                    List<MediaItem>.from(
                                                        playlistController.songList),
                                                    0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController
                                                            .playlist.value.title,
                                                        type: PlaylingFromType.PLAYLIST));
                                              },
                                              icon: Icon(
                                                Icons.play_circle,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              ),
                                            ),
                                            // Enqueue button
                                            IconButton(
                                              onPressed: () {
                                                Get.find<PlayerController>()
                                                    .enqueueSongList(playlistController
                                                        .songList
                                                        .toList())
                                                    .whenComplete(() {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(snackbar(
                                                            context, "songEnqueueAlert".tr,
                                                            size: SanckBarSize.MEDIUM));
                                                  }
                                                });
                                              },
                                              icon: Icon(
                                                Icons.merge,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              ),
                                            ),
                                            // Shuffle button
                                            IconButton(
                                              onPressed: () {
                                                final songsToplay = List<MediaItem>.from(
                                                    playlistController.songList);
                                                songsToplay.shuffle();
                                                songsToplay.shuffle();
                                                playerController.playPlayListSong(
                                                    songsToplay, 0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController
                                                            .playlist.value.title,
                                                        type: PlaylingFromType.PLAYLIST));
                                              },
                                              icon: Icon(
                                                Icons.shuffle,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              ),
                                            ),
                                            // Download button
                                            GetX<Downloader>(builder: (controller) {
                                              final id = playlistController
                                                  .playlist.value.playlistId;
                                              return IconButton(
                                                onPressed: () {
                                                  if (playlistController
                                                      .isDownloaded.isTrue) {
                                                    return;
                                                  }
                                                  controller.downloadPlaylist(id,
                                                      playlistController.songList.toList());
                                                },
                                                icon: playlistController.isDownloaded.isTrue
                                                    ? const Icon(Icons.download_done)
                                                    : controller.playlistQueue
                                                                .containsKey(id) &&
                                                            controller.currentPlaylistId
                                                                    .toString() ==
                                                                id
                                                    ? Stack(
                                                        children: [
                                                          Center(
                                                              child: Text(
                                                                  "${controller.playlistDownloadingProgress.value}/${playlistController.songList.length}",
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .titleMedium!
                                                                      .copyWith(
                                                                          fontSize: 10,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .bold))),
                                                          const Center(
                                                              child: LoadingIndicator(
                                                            dimension: 30,
                                                          ))
                                                        ],
                                                      )
                                                    : controller.playlistQueue
                                                            .containsKey(id)
                                                        ? const Stack(
                                                            children: [
                                                              Center(
                                                                  child: Icon(
                                                                Icons.hourglass_bottom,
                                                                size: 20,
                                                              )),
                                                              Center(
                                                                  child: LoadingIndicator(
                                                                dimension: 30,
                                                              ))
                                                            ],
                                                          )
                                                        : const Icon(Icons.download),
                                              );
                                            }),
                                            if (playlistController.isAddedToLibrary.isTrue)
                                              IconButton(
                                                  onPressed: () {
                                                    playlistController.syncPlaylistSongs();
                                                  },
                                                  icon: const Icon(Icons.cloud_sync)),
                                            if (playlistController
                                                .playlist.value.isPipedPlaylist)
                                              IconButton(
                                                  icon: const Icon(
                                                    Icons.block,
                                                    size: 20,
                                                  ),
                                                  splashRadius: 10,
                                                  onPressed: () {
                                                    Get.nestedKey(ScreenNavigationSetup.id)!
                                                        .currentState!
                                                        .pop();
                                                    Get.find<LibraryPlaylistsController>()
                                                        .blacklistPipedPlaylist(
                                                            playlistController
                                                                .playlist.value);
                                                    ScaffoldMessenger.of(Get.context!)
                                                        .showSnackBar(snackbar(Get.context!,
                                                            "playlistBlacklistAlert".tr,
                                                            size: SanckBarSize.MEDIUM));
                                                  }),
                                            if (playlistController
                                                .playlist.value.isCloudPlaylist)
                                              IconButton(
                                                  visualDensity:
                                                      const VisualDensity(vertical: -3),
                                                  splashRadius: 10,
                                                  onPressed: () {
                                                    final content =
                                                        playlistController.playlist.value;
                                                    if (content.isPipedPlaylist) {
                                                      Share.share(
                                                          "https://piped.video/playlist?list=${content.playlistId}");
                                                    } else {
                                                      final isPlaylistIdPrefixAvlbl = content
                                                              .playlistId
                                                              .substring(0, 2) ==
                                                          "VL";
                                                      String url =
                                                          "https://youtube.com/playlist?list=";

                                                      url = isPlaylistIdPrefixAvlbl
                                                              ? url +
                                                                  content.playlistId.substring(2)
                                                              : url + content.playlistId;
                                                      Share.share(url);
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.share,
                                                    size: 20,
                                                  )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Widget de Ordenación y Búsqueda (como un encabezado de sección)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverHeaderDelegate(
                      minHeight: 40,
                      maxHeight: 40,
                      child: Container(
                        color: Theme.of(context).canvasColor,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 5),
                          child: Obx(() => SortWidget(
                                tag: playlistController
                                    .playlist.value.playlistId,
                                screenController: playlistController,
                                isSearchFeatureRequired: true,
                                isPlaylistRearrageFeatureRequired:
                                    !playlistController
                                            .playlist.value.isCloudPlaylist &&
                                        playlistController
                                                .playlist.value.playlistId !=
                                            "LIBRP" &&
                                        playlistController
                                                .playlist.value.playlistId !=
                                            "SongDownloads" &&
                                        playlistController
                                                .playlist.value.playlistId !=
                                            "SongsCache",
                                isSongDeletetioFeatureRequired:
                                    !playlistController
                                        .playlist.value.isCloudPlaylist,
                                itemCountTitle:
                                    "${playlistController.songList.length}",
                                itemIcon: Icons.music_note,
                                titleLeftPadding: 9,
                                requiredSortTypes: buildSortTypeSet(),
                                onSort: playlistController.onSort,
                                onSearch: playlistController.onSearch,
                                onSearchClose: playlistController.onSearchClose,
                                onSearchStart: playlistController.onSearchStart,
                                startAdditionalOperation:
                                    playlistController.startAdditionalOperation,
                                selectAll: playlistController.selectAll,
                                performAdditionalOperation: playlistController
                                    .performAdditionalOperation,
                                cancelAdditionalOperation: playlistController
                                    .cancelAdditionalOperation,
                              )),
                        ),
                      ),
                    ),
                  ),

                  // Lista de canciones o mensaje de vacío
                  Obx(() {
                    if (playlistController.songList.isEmpty) {
                      return SliverFillRemaining(
                        // Ocupa el espacio restante si está vacío
                        child: Center(
                          child: Text(
                            "emptyPlaylist".tr,
                            style: textTheme.titleMedium,
                          ),
                        ),
                      );
                    } else {
                      // Usamos SliverPadding para añadir padding solo a la lista
                      return SliverPadding(
                        padding: const EdgeInsets.only(
                            bottom: 100), // Padding inferior para la miniplayer
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = playlistController.songList[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        20.0), // padding igual que cabecera y filtros
                                child: SongListTile(
                                  song: song,
                                  isPlaylistOrAlbum: true,
                                  playlist: playlistController.playlist.value,
                                  onTap: () {
                                    playerController.playPlayListSong(
                                      List<MediaItem>.from(
                                          playlistController.songList),
                                      index,
                                      playfrom: PlaylingFrom(
                                        name: playlistController
                                            .playlist.value.title,
                                        type: PlaylingFromType.PLAYLIST,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: playlistController.songList.length,
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
      ),
    );
  }

  // Necesitamos una clase Delegate para SliverPersistentHeader
  static Set<SortType> buildSortTypeSet() {
    final Set<SortType> requiredSortTypes = {};

    // Usa los valores reales de tu enum SortType
    requiredSortTypes.add(SortType.Name);
    requiredSortTypes.add(SortType.Date);
    requiredSortTypes.add(SortType.Duration);
    requiredSortTypes.add(SortType.RecentlyPlayed);

    return requiredSortTypes;
  }
}

// Delegate para el SliverPersistentHeader que contiene el SortWidget
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
