import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/routes.dart';
import 'package:netmirror/widgets/ott_drawer.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();
  L.only = [];
  L.logLevel = LogLevel.debug;
  // L.stackStrace = true;

  if (isDesk) {
    await windowManager.ensureInitialized();
    const WindowOptions windowOptions = WindowOptions(
      size: Size(400, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // if (isDesk) {
  //   databaseFactory = databaseFactoryFfi;
  // }

  await DB.instance.database;
  Downloader.instance;

  // if (!isDesk) {
  //   await Workmanager().initialize(
  //     callbackDispatcher,
  //     isInDebugMode: true,
  //   );
  // }

  runApp(ProviderScope(overrides: [], child: MainApp()));
}

const themeColor = Color.fromARGB(255, 171, 109, 105);
final darkScheme = ColorScheme.fromSeed(
  seedColor: themeColor,
  brightness: Brightness.dark,
  dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
);

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
    // WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    super.dispose();
  }

  bool handleKeyEvent(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final hk = HardwareKeyboard.instance;
    final lk = e.logicalKey;
    final isMeta = Platform.isMacOS ? hk.isMetaPressed : hk.isControlPressed;
    final ottIndex = getOttIndexFromRoute(SettingsOptions.currentScreen);

    if (lk == LogicalKeyboardKey.escape) {
      routes.pop();
      return true;
    } else if (lk == LogicalKeyboardKey.arrowLeft &&
        isMeta &&
        !hk.isAltPressed) {
      routes.pop();
      return true;
    } else if (lk == LogicalKeyboardKey.comma && isMeta) {
      routes.push("/settings");
      return true;
    } else if (lk == LogicalKeyboardKey.keyJ && isMeta) {
      routes.push("/downloads");
      return true;
    } else if (lk == LogicalKeyboardKey.keyF && isMeta) {
      routes.push("/search/$ottIndex");
      return true;
    } else if (lk == LogicalKeyboardKey.keyH && isMeta) {
      routes.push("/history");
      return true;
    } else if (lk == LogicalKeyboardKey.keyU && isMeta) {
      routes.push("/profile");
      return true;
    }
    return false;
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   log("============== App State: $state ==============");
  //   if (state == AppLifecycleState.detached ||
  //       state == AppLifecycleState.paused) {
  // pauseFlags.updateAll((key, value) => true);

  // runs when app closed
  // DownloadHelper.instance.continueDownloadAfterAppOpen();
  // log("Ids: $ids");
  // log("App closed");
  // Workmanager().registerOneOffTask(
  //   "downloadTask",
  //   "downloadTask",
  //   // inputData: {"downloadId": ids[0]},
  //   existingWorkPolicy: ExistingWorkPolicy.replace,
  // );
  // }
  // }

  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: darkScheme,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    // ── AppBar ──────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      toolbarHeight: isDesk ? 28 : 48,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: isDesk ? 14 : 20),
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    // ── Card ────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
    ),
    // ── ListTile ────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 8,
    ),
    // ── Input / TextField ────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    ),
    // ── SnackBar ─────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF2C2C2E),
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    // ── Buttons ──────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // ── Chip ─────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.white70),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    // ── Divider ──────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2C2C2E),
      thickness: 1,
      space: 1,
    ),
    // ── Dialog ───────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    // ── Switch ───────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkScheme.primary;
        }
        return Colors.grey.withValues(alpha: 0.4);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    // ── Progress indicator ────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: darkScheme.primary,
      linearTrackColor: Colors.white12,
      circularTrackColor: Colors.white12,
    ),
    // ── Bottom sheet ─────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    // ── PopupMenu ────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(color: Colors.white),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: GlobalKey(),
      debugShowCheckedModeBanner: false,
      darkTheme: theme,
      theme: theme,
      routerConfig: routes,
    );
  }
}

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     if (task == "downloadTask") {
//       logger.f("Download task started");
//       final ids = await DownloadDb.instance.downloadingIds();
//       // final downloadId = inputData!["downloadId"]! as int;
//       await DownloadDb.instance.processDownload(ids[0]);
//       // await DownloadHelper.instance.continueDownloadAfterAppOpen();
//       return true;
//     }
//     return true;
//   });
// }
