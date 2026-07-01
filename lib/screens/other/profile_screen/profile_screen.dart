import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/models/watch_list_model.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final double _imgHeight = isDesk ? 120 : 170;

class _ProfileScreenState extends State<ProfileScreen> {
  List<WatchList> myList = [];
  List<WatchHistory> watchHistory = [];

  @override
  void initState() {
    super.initState();
    _initial();
  }

  void _initial() async {
    final [x, y] = await Future.wait([
      DB.watchList.getAll(),
      DB.watchHistory.getAll(),
    ]);

    setState(() {
      myList = x as List<WatchList>;
      watchHistory = y as List<WatchHistory>;
      log(myList.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLgScreen = size.width > kLgScreenWidth;
    const headStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesk,
        title: windowDragAreaWithChild(
          [
            Text(
              "Profile",
              style: TextStyle(
                fontSize: isDesk ? 14 : 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          actions: [
            IconButton(
              onPressed: () => GoRouter.of(context).push("/downloads"),
              icon: Icon(
                HugeIcons.strokeRoundedDownload05,
                size: isDesk ? 20 : 26,
              ),
            ),
            IconButton(
              onPressed: () =>
                  GoRouter.of(context).push("/settings-audio-tracks"),
              icon: Icon(Icons.settings_outlined, size: isDesk ? 18 : 26),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── My List ──────────────────────────────────────────────
              if (myList.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  "My List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: _imgHeight + 10,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: myList.map((e) {
                      final ott = OTT.fromId(e.ottId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => goToMovie(context, ott.id, e.id),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: ott.getImg(e.id),
                              height: _imgHeight,
                              width: _imgHeight * ott.aspectRatio,
                              cacheManager: e.isShow
                                  ? ShowCacheManager.instance
                                  : MovieCacheManager.instance,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              // ── Watch History ─────────────────────────────────────────
              if (watchHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Watch History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: _imgHeight + 10 + 3.5,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: watchHistory.map((e) {
                      final ott = OTT.fromId(e.ottId);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => goToMovie(context, ott.id, e.id),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: ott.getImg(e.id),
                                  height: _imgHeight,
                                  width: _imgHeight * ott.aspectRatio,
                                  cacheManager: e.isShow
                                      ? ShowCacheManager.instance
                                      : MovieCacheManager.instance,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _imgHeight * ott.aspectRatio,
                            height: 3.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: e.current / e.duration,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
              // ── Links section ─────────────────────────────────────────
              const SizedBox(height: 24),
              // Telegram card
              _ProfileLinkCard(
                onTap: () async {
                  final uri = Uri.parse("https://t.me/+dOVQE6fRw3U3YWRl");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                leading: Icon(
                  HugeIcons.strokeRoundedTelegram,
                  size: 36,
                  color: Colors.blue[400],
                ),
                title: "Join Telegram",
                subtitle: "Request Movies, Updates, Report Bugs",
              ),
              const SizedBox(height: 10),
              // NetMirror site card
              _ProfileLinkCard(
                onTap: () async {
                  final uri = Uri.parse("https://netmirror.app");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/logos/netmirror.png",
                    height: 36,
                    width: 36,
                  ),
                ),
                title: "NetMirror",
                subtitle: "Official Netmirror Site",
              ),
              // ── Attribution ───────────────────────────────────────────
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Created by  ",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextSpan(
                          text: "Sarisa Jaya Surya",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable M3 card for profile link items.
class _ProfileLinkCard extends StatelessWidget {
  const _ProfileLinkCard({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
