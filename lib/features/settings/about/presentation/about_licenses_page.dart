import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_page_frame.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import 'widgets/about_doc_widgets.dart';

/// Open-source licenses rendered in the app's own style instead of the
/// Material `LicensePage`. It reads the real `LicenseRegistry` stream, groups
/// the entries by package, and lets the reader search and expand each one.
class AboutLicensesPage extends StatefulWidget {
  const AboutLicensesPage({super.key, this.licenses});

  /// Overridable for tests; defaults to the real [LicenseRegistry] stream.
  final Stream<LicenseEntry>? licenses;

  @override
  State<AboutLicensesPage> createState() => _AboutLicensesPageState();
}

class _AboutLicensesPageState extends State<AboutLicensesPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expanded = {};
  List<_LicensePackage>? _packages;
  String _query = '';
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final buffers = <String, StringBuffer>{};
    await for (final entry in widget.licenses ?? LicenseRegistry.licenses) {
      final text = entry.paragraphs
          .map((paragraph) => paragraph.text)
          .join('\n\n')
          .trim();
      for (final package in entry.packages) {
        final buffer = buffers.putIfAbsent(package, () => StringBuffer());
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(text);
      }
    }

    final packages = buffers.entries
        .map((entry) => _LicensePackage(entry.key, entry.value.toString()))
        .toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    if (!mounted) return;
    // Show the list as soon as it is ready; the version is decorative and
    // resolves independently.
    setState(() => _packages = packages);

    String? version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Version is decorative here; the list works without it.
    }
    if (!mounted || version == null) return;
    setState(() => _version = version);
  }

  void _toggle(String name) {
    setState(() {
      if (!_expanded.add(name)) _expanded.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final packages = _packages;
    final query = _query.trim().toLowerCase();
    final filtered = packages
        ?.where((package) => package.name.toLowerCase().contains(query))
        .toList();
    final version = _version;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        constrainWidth: false,
        children: [
          const SettingsDetailHeader(
            eyebrow: '关于',
            title: '开源许可',
            showAction: false,
          ),
          const SizedBox(height: 14),
          AboutDocIntro(
            version == null
                ? 'Dudo 使用了以下开源组件。感谢它们的作者与贡献者。'
                : 'Dudo $version 使用了以下开源组件。感谢它们的作者与贡献者。',
          ),
          const SizedBox(height: 12),
          _SearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          if (packages == null)
            const _LicensesLoading()
          else if (filtered!.isEmpty)
            _LicensesEmpty(query: _query)
          else
            for (final package in filtered) ...[
              _LicenseTile(
                package: package,
                expanded: _expanded.contains(package.name),
                onToggle: () => _toggle(package.name),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 6),
          AboutDocFooter('共 ${packages?.length ?? 0} 个开源组件'),
        ],
      ),
    );
  }
}

class _LicensePackage {
  const _LicensePackage(this.name, this.text);

  final String name;
  final String text;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 17, color: DudoColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '搜索开源组件',
                hintStyle: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseTile extends StatelessWidget {
  const _LicenseTile({
    required this.package,
    required this.expanded,
    required this.onToggle,
  });

  final _LicensePackage package;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: DudoTextStyles.sans(
                            color: DudoColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expanded ? '收起许可证' : '点击查看许可证',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: DudoColors.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SelectableText(
                package.text,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondaryDark,
                  fontSize: 11,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LicensesLoading extends StatelessWidget {
  const _LicensesLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _LicensesEmpty extends StatelessWidget {
  const _LicensesEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          query.trim().isEmpty ? '暂无开源许可信息' : '没有匹配「${query.trim()}」的组件',
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
