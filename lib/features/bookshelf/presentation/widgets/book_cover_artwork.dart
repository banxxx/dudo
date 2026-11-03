import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import 'cover_title_overlay.dart';

/// Renders a book cover from the best available source: the pending crop in
/// the editor, the user's saved local cover, the remote cover, or the generated
/// paper cover used for books without artwork.
class BookCoverArtwork extends StatelessWidget {
  const BookCoverArtwork({
    super.key,
    required this.title,
    this.author,
    this.coverUrl,
    this.customCoverPath,
    this.pendingBytes,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.compactGeneratedTitle = true,
    this.showTitleOverlay = false,
  });

  final String title;
  final String? author;
  final String? coverUrl;
  final String? customCoverPath;
  final Uint8List? pendingBytes;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool compactGeneratedTitle;

  /// Prints the Dudo title lockup over user supplied artwork. Covers that come
  /// from the network or that are generated already carry their own lettering.
  final bool showTitleOverlay;

  @override
  Widget build(BuildContext context) {
    final Widget artwork;
    var userArtwork = false;
    if (pendingBytes != null) {
      userArtwork = true;
      artwork = Image.memory(
        pendingBytes!,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _remoteOrGenerated(),
      );
    } else if (customCoverPath != null && customCoverPath!.isNotEmpty) {
      userArtwork = true;
      artwork = Image.file(
        File(customCoverPath!),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _remoteOrGenerated(),
      );
    } else {
      artwork = _remoteOrGenerated();
    }

    final content = showTitleOverlay && userArtwork
        ? Stack(
            fit: StackFit.expand,
            children: [
              artwork,
              CoverTitleOverlay(title: title, author: author),
            ],
          )
        : artwork;

    return ClipRRect(borderRadius: borderRadius, child: content);
  }

  Widget _remoteOrGenerated() {
    final url = coverUrl?.trim();
    if (url == null || url.isEmpty) return _generated();
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => _generated(),
    );
  }

  Widget _generated() {
    final trimmedTitle = title.trim().isEmpty ? '书' : title.trim();
    final trimmedAuthor =
        author?.trim().isNotEmpty == true ? author!.trim() : 'Dudo';
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 120;
        final labelSize = (width * 0.09).clamp(8.0, 12.0);
        final titleSize = (width * 0.19).clamp(15.0, 28.0);
        final padding = (width * 0.12).clamp(10.0, 16.0);
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DudoColors.textPrimary,
                DudoColors.primary,
                DudoColors.accentSoft,
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '阅读收藏',
                style: DudoTextStyles.sans(
                  color: DudoColors.surfaceHigh,
                  fontSize: labelSize,
                ),
              ),
              Text(
                _compactTitle(trimmedTitle),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: DudoTextStyles.serif(
                  color: DudoColors.surfaceHigh,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              Text(
                trimmedAuthor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: const Color(0xFFE8E4D8),
                  fontSize: labelSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _compactTitle(String value) {
    if (!compactGeneratedTitle) return value;
    final characters = value.runes.toList();
    if (characters.length <= 4) return value;
    return String.fromCharCodes(characters.take(4));
  }
}
