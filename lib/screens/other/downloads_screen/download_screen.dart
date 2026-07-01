import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/downloader/download_db.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/screens/external_plyer.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.seriesId});
  final String? seriesId;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

const l = L("download_screen");

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadItem> downloads = [];
  StreamSubscription<DownloadProgress>? _progressSubscription;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadDownloads();
    _progressSubscription = Downloader.instance.progressStream.listen((update) {
      final downloadId = update.id;

      l.debug("download id: $downloadId");

      // when new download item added
      // handles both movie and series, in case of movie, both seriesId are null and became equal
      if (update.newItem && update.seriesId == widget.seriesId) {
        DownloadDb.instance.getDownloadItem(downloadId).then((x) {
          if (mounted) {
            setState(() {
              downloads.add(x);
            });
          }
        });
        return;
      }

      final currItem = downloads.firstWhereOrNull((e) => e.id == downloadId);

      if (currItem == null) return;

      final statusChanged =
          (update.status != null) && update.status != currItem.status;

      final progress = update;
      final progressChanged = progress.isAudio!
          ? (progress.progress != currItem.audioProgress)
          : (progress.progress != currItem.videoProgress);

      if ((progressChanged || update.progress == null || statusChanged) &&
          mounted) {
        if (update.totalEpisodesPlus != null) {
          log("Total episodes added in inside IF: ${update.totalEpisodesPlus}");
        }
        setState(() {
          currItem.update(progress);
        });
      }
    });
  }

  Future<void> loadDownloads() async {
    late final List<DownloadItem> x;
    if (widget.seriesId == null) {
      x = await DownloadDb.instance.getAllDownloads();
    } else {
      x = await DownloadDb.instance.getSeriesEpisodes(widget.seriesId!);
    }
    l.info("downloads count: ${x.length}");
    setState(() {
      downloads = x;
    });
  }

  void openMovie(String id, int ottId) {
    GoRouter.of(context).push("/movie/$ottId/$id");
  }

  static void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> requestPermission() async {
    if (true) {
      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
  }

  Future<void> playWithAndroidVlc(String file) async {
    requestPermission();
    String subtitlePath = "/storage/emulated/0/Download/80243261-ar.srt";
    final intent = AndroidIntent(
      action: 'action_view',
      // data: file.replaceFirst(".mp4", ".m3u8"),
      data: file,
      type: "application/x-mpegURL",
      package: 'org.videolan.vlc',
      arrayArguments: {
        'subtitles_location': [subtitlePath],
        'sub_paths': [subtitlePath],
      },
      arguments: {
        'title': "Outlander",
        'from_start': true,
        'subtitles_location': subtitlePath,
        'sub_file': subtitlePath, // Alternative key that VLC might recognize
        'extra_subtitles_file_path': subtitlePath,
        'position': 1000,
        // 'extra_duration': 1000,
      },
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_GRANT_READ_URI_PERMISSION],
    );
    await intent.launch();
  }

  void delete(String id, String type, int index) {
    if (type == "series") {
      Downloader.deleteSeries(id);
    } else {
      Downloader.deleteItem(id);
    }
    setState(() {
      downloads.removeAt(index);
    });
  }

  void test() async {
    log("support: ${await getApplicationSupportDirectory()}");
    log("app doc: ${await getApplicationDocumentsDirectory()}");
    log("temp: ${await getTemporaryDirectory()}");
    log("ext stor: ${await getExternalStorageDirectory()}");
    log(" ${await getExternalStorageDirectories()}");
    log("downloads: ${await getDownloadsDirectory()}");
    log(" ${await FilePicker.platform.getDirectoryPath()}");
    // log("library: ${await getLibraryDirectory()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesk,
        title: windowDragAreaWithChild([const Text('Downloads')]),
      ),
      body: downloads.isEmpty
          ? Builder(
              builder: (context) {
                final cs = Theme.of(context).colorScheme;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No downloads yet",
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: downloads.length,
              itemBuilder: (context, i) => buildDownloadItem(downloads[i], i),
            ),
    );
  }

  Widget _buildProgressAudioOrVideo(
    DownloadItem item,
    int firstNonDownloadAudioIndex,
  ) {
    int fndaIndex = firstNonDownloadAudioIndex;
    bool isAudioDownloading = fndaIndex != -1;
    bool showAudioCount = isAudioDownloading && item.audioLangs.length > 1;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: isAudioDownloading
                ? "Progress: Audio ${showAudioCount ? "${fndaIndex + 1}/${item.audioLangs.length}" : ""} $Dot  "
                : "Progress: Video $Dot  ",
            style: const TextStyle(
              fontSize: 12,
            ), // Default color for the prefix
          ),
          TextSpan(
            text: isAudioDownloading
                ? "${item.audioProgress}%"
                : "${item.videoProgress}%",
            style: TextStyle(fontSize: 14), // Color for the status
          ),
        ],
      ),
    );
  }

  Widget buildDownloadItem(DownloadItem item, int i) {
    final cs = Theme.of(context).colorScheme;
    final firstNonDownloadAudioIndex = item.audioLangs.indexWhere(
      (e) => !e.status,
    );
    final isAudioDownloading = firstNonDownloadAudioIndex != -1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (item.type == "series") {
              context.push("/downloads", extra: item.id);
              return;
            }
            l.debug(
              "download id: ${item.id}, playlist path: ${item.playlistPath}",
            );
            final id = item.seriesId ?? item.id;
            final movie = await DB.movie.get(id, item.ottId);
            if (movie == null) {
              log("Movie not found in DB for id: $id");
              return;
            }
            GoRouter.of(context).push(
              "/player",
              extra: (
                url: item.playlistPath,
                movie: movie,
                watchHistory: null,
                seasonNumber: item.seasonNumber,
                episodeNumber: item.episodeNumber,
                subtitleUrl: null,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 8,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.thumbnail,
                        fit: BoxFit.cover,
                        width: 150,
                        height: 86,
                        errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 86,
                          color: const Color(0xFF2A2A2A),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (item.type == "series") ...[
                            Text(
                              "Episodes: ${item.completedEpisodes}/${item.totalEpisodes}",
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            if (item.completedEpisodes == item.totalEpisodes)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Completed",
                                  style: TextStyle(
                                    color: DownloadColors.completed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ] else ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (item.type == "episode")
                                  buildChip(
                                    "S${item.seasonNumber} $Dot E${item.episodeNumber!}",
                                  ),
                                if (item.resolution.isNotEmpty)
                                  buildChip(item.resolution),
                                if (item.runtime != null)
                                  buildChip(item.runtime!),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _buildProgressAudioOrVideo(
                              item,
                              firstNonDownloadAudioIndex,
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Status: ',
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: item.status,
                                    style: TextStyle(
                                      color: DownloadColors.fromStatus(
                                        item.status,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.type == "series")
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                  ],
                ),
                // Progress + action row
                if (item.status != "completed") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildIconButton(Icons.more_vert_rounded, () {
                        final player = ExternalPlayer.offlineFile;
                        showMenu(
                          position: RelativeRect.fromLTRB(40, 200, 0, 0),
                          context: context,
                          items: [
                            PopupMenuItem(
                              onTap: () => delete(item.id, item.type, i),
                              child: const Text("Delete Download"),
                            ),
                            PopupMenuItem(
                              onTap: () => openMovie(
                                item.seriesId ?? item.id,
                                item.ottId,
                              ),
                              child: const Text("Go to Page"),
                            ),
                            if (Platform.isAndroid)
                              PopupMenuItem(
                                onTap: () =>
                                    playWithAndroidVlc(item.playlistPath),
                                child: const Text("Play With VLC"),
                              ),
                            if (Platform.isMacOS)
                              PopupMenuItem(
                                onTap: () => player.iina(item.playlistPath),
                                child: const Text("Play With IINA"),
                              ),
                            if (Platform.isWindows)
                              PopupMenuItem(
                                onTap: () => player.wmp(item.playlistPath),
                                child: const Text(
                                  "Play With Windows Media Player",
                                ),
                              ),
                            if (isDesk) ...[
                              PopupMenuItem(
                                onTap: () => player.vlc(item.playlistPath),
                                child: const Text("VLC"),
                              ),
                              PopupMenuItem(
                                onTap: () => player.mpv(item.playlistPath),
                                child: const Text("MPV"),
                              ),
                            ],
                            PopupMenuItem(
                              onTap: () => _launchUrl(item.playlistPath),
                              child: const Text("Open in Browser"),
                            ),
                          ],
                        );
                      }),
                      if (item.status == "paused" || item.status == "failed")
                        _buildIconButton(Icons.play_arrow_rounded, () {
                          Downloader.instance.resumeDownload(item.id);
                        }),
                      if (item.status == "downloading" ||
                          item.status == "pending")
                        _buildIconButton(Icons.pause_rounded, () {
                          Downloader.instance.pauseDownload(item.id);
                        }),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: (item.audioPrefix.isNotEmpty &&
                                    item.audioProgress < 100
                                ? item.audioProgress
                                : item.videoProgress) /
                                100,
                            color: isAudioDownloading
                                ? cs.tertiary
                                : cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 18,
        icon: Icon(icon),
        color: Colors.white70,
      ),
    );
  }

  Widget buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}
