// The example shows the deprecated 0.5.x compatible API on purpose.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';
import 'package:tray_manager/legacy.dart';

import 'tray_controller.dart';
import 'widgets/event_footer.dart';
import 'widgets/option_chip.dart';
import 'widgets/palette.dart';

// tray_manager through its 0.5.x compatible API (package:tray_manager/legacy.dart):
// one tray icon, the classic `trayManager` calls, a `TrayListener`.
//
//   tray_controller.dart   every trayManager call, the context menu, the listener
//   widgets/               the few widgets the window is made of (no Material)
//
// This is deliberately the small example. The full one — several icons at once,
// animated icons, every native property with read-back, and an acceptance
// checklist — is nativeapi's tray_icon_example:
// https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples/tray_icon_example

const kFullExampleUrl =
    'github.com/libnativeapi/nativeapi-flutter/tree/main/examples/tray_icon_example';

void main() {
  runApp(const TrayManagerExampleApp());
}

class TrayManagerExampleApp extends StatelessWidget {
  const TrayManagerExampleApp({
    super.key,
    this.shell = const Shell(),
    this.fontFamily,
  });

  final Widget shell;

  /// Null uses the platform's font; a test has to name one it has loaded.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'tray_manager example',
      color: Palette.light.accent,
      debugShowCheckedModeBanner: false,
      builder: (context, _) {
        final palette = Palette.of(context);
        return DefaultTextStyle(
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            height: 1.3,
            color: palette.text,
          ),
          child: shell,
        );
      },
    );
  }
}

/// Lifecycle strip, one row per compatible API, event footer.
class Shell extends StatefulWidget {
  const Shell({super.key, this.controller});

  /// Defaults to a controller that creates the tray icon right away.
  final TrayController? controller;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final TrayController _controller = widget.controller ?? TrayController();

  static const _titles = <String, String>{
    'No title': '',
    '42%': '42%',
    '00:12': '00:12',
    '你好': '你好',
  };

  static const _tooltips = <String, String>{
    'Short': kDefaultTooltip,
    'Long':
        'A long tooltip that says rather more than a tooltip usually should, '
        'to see where the platform cuts it off',
    '2 lines': 'Line one\nLine two',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final c = _controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            _lifecycleStrip(palette),
            Expanded(
              child: ListView(
                children: [
                  _stateBlock(palette),
                  OptionRow(
                    label: 'Icon',
                    children: [
                      OptionChip(
                        label: 'Glyph',
                        selected: c.iconPath == kGlyphIcon,
                        onTap: c.created ? () => c.setIcon(kGlyphIcon) : null,
                      ),
                      OptionChip(
                        label: 'Colour',
                        selected: c.iconPath == kColourIcon,
                        onTap: c.created ? () => c.setIcon(kColourIcon) : null,
                      ),
                    ],
                  ),
                  OptionRow(
                    label: 'Template',
                    children: [
                      OptionChip(
                        label: 'On',
                        selected: c.isTemplate,
                        onTap: c.created ? () => c.setTemplate(true) : null,
                      ),
                      OptionChip(
                        label: 'Off',
                        selected: !c.isTemplate,
                        onTap: c.created ? () => c.setTemplate(false) : null,
                      ),
                      if (!TrayController.iconLayoutSupported)
                        const Hint('macOS only'),
                    ],
                  ),
                  OptionRow(
                    label: 'Icon size',
                    children: [
                      for (final size in const [12, 18, 22])
                        OptionChip(
                          label: '$size',
                          selected: c.iconSize == size,
                          onTap: c.created ? () => c.setIconSize(size) : null,
                        ),
                      if (!TrayController.iconLayoutSupported)
                        const Hint('macOS only'),
                    ],
                  ),
                  OptionRow(
                    label: 'Position',
                    children: [
                      for (final position in TrayIconPosition.values)
                        OptionChip(
                          label: 'Icon ${position.name}',
                          selected: c.iconPosition == position,
                          onTap: c.created
                              ? () => c.setIconPosition(position)
                              : null,
                        ),
                      Hint(
                        TrayController.iconLayoutSupported
                            ? 'of the title'
                            : 'macOS only',
                      ),
                    ],
                  ),
                  OptionRow(
                    label: 'Title',
                    children: [
                      for (final MapEntry(:key, :value) in _titles.entries)
                        OptionChip(
                          label: key,
                          selected: c.title == value,
                          onTap: c.created ? () => c.setTitle(value) : null,
                        ),
                      if (!TrayController.titleSupported)
                        const Hint('no titles on Windows'),
                    ],
                  ),
                  OptionRow(
                    label: 'Tooltip',
                    children: [
                      for (final MapEntry(:key, :value) in _tooltips.entries)
                        OptionChip(
                          label: key,
                          selected: c.tooltip == value,
                          onTap: c.created ? () => c.setToolTip(value) : null,
                        ),
                    ],
                  ),
                  OptionRow(
                    label: 'Menu',
                    children: [
                      OptionChip(
                        label: 'Pop up context menu',
                        onTap: c.created && TrayController.popUpSupported
                            ? c.popUpContextMenu
                            : null,
                      ),
                      Hint(
                        TrayController.popUpSupported
                            ? 'or right-click the icon'
                            : 'the shell opens it on Linux',
                      ),
                    ],
                  ),
                  _fullExampleNote(palette),
                ],
              ),
            ),
            EventFooter(controller: c),
          ],
        ),
      ),
    );
  }

  Widget _lifecycleStrip(Palette palette) {
    final created = _controller.created;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'trayManager',
              style: TextStyle(fontSize: 11, color: palette.muted),
            ),
          ),
          OptionChip(
            label: 'Create',
            selected: created,
            onTap: created ? null : _controller.create,
          ),
          const SizedBox(width: 5),
          OptionChip(
            label: 'Destroy',
            onTap: created ? _controller.destroy : null,
          ),
        ],
      ),
    );
  }

  /// What the system says, as opposed to what the chips asked for.
  Widget _stateBlock(Palette palette) {
    final bounds = _controller.bounds;
    final text = !_controller.created
        ? 'destroyed'
        : !TrayController.boundsSupported
        ? 'getBounds()  not available on Linux'
        : bounds == null
        ? 'getBounds()  …'
        : 'getBounds()  ${bounds.left.round()}, ${bounds.top.round()}  '
              '${bounds.width.round()} × ${bounds.height.round()}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: palette.mono)),
          OptionChip(
            label: 'Refresh',
            onTap: _controller.created && TrayController.boundsSupported
                ? _controller.refreshBounds
                : null,
          ),
        ],
      ),
    );
  }

  Widget _fullExampleNote(Palette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.accentSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Looking for the full example?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'This window only covers the 0.5.x compatible API. Several icons '
              'at once, animated icons, every native property and an acceptance '
              'checklist are in nativeapi\'s tray_icon_example:',
            ),
            const SizedBox(height: 6),
            Text(kFullExampleUrl, style: palette.mono),
          ],
        ),
      ),
    );
  }
}
