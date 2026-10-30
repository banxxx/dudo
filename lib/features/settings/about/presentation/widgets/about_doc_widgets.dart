import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../shared/theme/app_fonts.dart';
import '../../../../../shared/theme/app_tokens.dart';

/// A short lead paragraph shown above the sections of a document page.
class AboutDocIntro extends StatelessWidget {
  const AboutDocIntro(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: DudoTextStyles.sans(
          color: DudoColors.onInkMuted,
          fontSize: 12.5,
          height: 1.6,
        ),
      ),
    );
  }
}

/// One titled section of a document page. Sections can carry a body paragraph,
/// a bullet list, or both.
class AboutDocSection extends StatelessWidget {
  const AboutDocSection({
    super.key,
    required this.title,
    this.body,
    this.bullets = const [],
    this.icon,
  });

  final String title;
  final String? body;
  final List<String> bullets;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final icon = this.icon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DudoColors.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: DudoColors.primary, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: DudoTextStyles.sans(
                color: DudoColors.secondaryDark,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final bullet in bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: DudoColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondaryDark,
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              if (bullet != bullets.last) const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

/// A footer line for document pages, e.g. the last-updated date.
class AboutDocFooter extends StatelessWidget {
  const AboutDocFooter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarDays, size: 13, color: DudoColors.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
