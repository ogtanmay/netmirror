import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';
import 'package:netmirror/screens/other/settings_screen/audios_preview_widget.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

const l = L("Settings_Screen");

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _resolutionController = TextEditingController();
  final _maxDownloadLimitController = TextEditingController(
    text: Downloader.maxDownloadLimit.toString(),
  );
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesk,
        title: windowDragAreaWithChild([const Text('Settings')]),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          // ── Playback section ────────────────────────────────────────
          _sectionHeader(context, "Playback"),
          _buildSwitch(
            "External Player for Streaming",
            SettingsOptions.externalPlayer,
            (value) {
              SettingsOptions.externalPlayer = value;
              setState(() {});
            },
          ),
          _buildSwitch(
            "External Player for Downloads",
            SettingsOptions.externalDownloadPlayer,
            (value) {
              SettingsOptions.externalDownloadPlayer = value;
              setState(() {});
            },
          ),
          // ── Quality section ──────────────────────────────────────────
          const Divider(height: 24),
          _sectionHeader(context, "Quality"),
          _buildSwitch(
            "Fast Mode — filter by Audio",
            SettingsOptions.fastModeByAudio,
            (value) {
              if (!SettingsOptions.fastModeByAudio &&
                  ref.read(audioTrackProvider).isEmpty) {
                showMssg("Please select an Audio Track first.");
                return;
              }
              SettingsOptions.fastModeByAudio = value;
              setState(() {});
            },
          ),
          _buildSwitch(
            "Fast Mode — filter by Video",
            SettingsOptions.fastModeByVideo,
            (value) {
              if (!SettingsOptions.fastModeByVideo &&
                  SettingsOptions.defaultResolution == "") {
                showMssg("Please select a default Quality first.");
                return;
              }
              SettingsOptions.fastModeByVideo = value;
              setState(() {});
            },
          ),
          ListTile(
            title: Text("Default Quality", style: labelStyle),
            trailing: DropdownMenu<String>(
              controller: _resolutionController,
              enableFilter: false,
              enableSearch: false,
              width: 140,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                suffixIconConstraints: const BoxConstraints(
                  maxHeight: 40,
                  maxWidth: 40,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 0.0,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              trailingIcon: const Icon(Icons.expand_more_rounded, size: 20),
              requestFocusOnTap: false,
              initialSelection: SettingsOptions.defaultResolution,
              onSelected: (value) {
                if (value != null) {
                  if (value.isEmpty) SettingsOptions.fastModeByVideo = false;
                  _resolutionController.text = value;
                  SettingsOptions.defaultResolution = value;
                  setState(() {});
                }
              },
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                  value: "1080p",
                  label: "1080p",
                  trailingIcon: Icon(Icons.high_quality),
                ),
                DropdownMenuEntry(
                  value: "720p",
                  label: "720p",
                  trailingIcon: Icon(Icons.hd),
                ),
                DropdownMenuEntry(
                  value: "480p",
                  label: "480p",
                  trailingIcon: Icon(Icons.sd),
                ),
                DropdownMenuEntry(
                  value: "",
                  label: "None",
                  trailingIcon: Icon(Icons.do_not_disturb),
                ),
              ],
            ),
          ),
          // ── Downloads section ────────────────────────────────────────
          const Divider(height: 24),
          _sectionHeader(context, "Downloads"),
          ListTile(
            title: Text("Max Download Limit", style: labelStyle),
            trailing: TextButton(
              onPressed: () => showPopupTextField(
                context,
                "Max Download Limit",
                _maxDownloadLimitController,
                () {
                  SettingsOptions.maxDownloadLimit = int.parse(
                    _maxDownloadLimitController.text,
                  );
                  Navigator.of(context).pop();
                  setState(() {});
                  return true;
                },
              ),
              child: Text(
                Downloader.maxDownloadLimit.toString(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          // ── Audio section ─────────────────────────────────────────────
          const Divider(height: 24),
          _sectionHeader(context, "Audio"),
          ListTile(
            title: Text("Audio Tracks", style: labelStyle),
            subtitle: AudiosPreviewWidget(),
            onTap: () => GoRouter.of(context).push('/settings-audio-tracks'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
            ),
          ),
          // ── Permissions section ──────────────────────────────────────
          const Divider(height: 24),
          _sectionHeader(context, "Permissions"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: () async {
                final status =
                    await Permission.manageExternalStorage.request();
                if (status.isGranted && mounted) {
                  showMssg("Storage permission granted.");
                }
              },
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text("Grant Storage Permission"),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isEnabled = true,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: isEnabled
          ? onChanged
          : null, // Disable the switch if isEnabled is false
    );
  }

  void showPopupTextField(
    BuildContext context,
    String title,
    TextEditingController controller,
    bool Function() onSave,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            controller: controller,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "Type here...",
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                onSave();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void showMssg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
