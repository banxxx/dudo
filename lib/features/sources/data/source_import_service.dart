import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/source_import_models.dart';
import 'importers/source_importer.dart';
import 'source_fetcher.dart';
import 'source_repository.dart';
import 'source_text_decoder.dart';

const _requestWithoutUaSuffix = '#requestWithoutUA';
const _maxSubscriptionDepth = 2;

class SourceImportException implements Exception {
  const SourceImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SourceImportService {
  const SourceImportService({
    required this.repository,
    required this.importers,
    SourceImportFetcher? fetcher,
    this.textDecoder = decodeSourceImportText,
  }) : _fetcher = fetcher;

  final SourceRepository repository;
  final List<SourceImporter> importers;
  final SourceImportFetcher? _fetcher;
  final Future<String> Function(List<int> bytes) textDecoder;

  SourceImportFetcher get _fetch => _fetcher ?? fetchSourceImportUrl;

  Future<String?> pickRuleFilePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
      allowMultiple: false,
      withData: false,
    );
    final files = result?.files;
    if (files == null || files.isEmpty) return null;
    final path = files.first.path;
    if (path == null || path.isEmpty) return null;
    return path;
  }

  Future<SourceImportPersistResult?> pickAndImportRuleFile({
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
  }) async {
    final path = await pickRuleFilePath();
    if (path == null) return null;

    return importRuleFilePath(path, existingStrategy: existingStrategy);
  }

  Future<SourceImportPersistResult> importRuleFilePath(
    String path, {
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const SourceImportException('无法读取规则文件');
    }

    final text = await _readRuleFile(file);
    return importRuleText(text, existingStrategy: existingStrategy);
  }

  Future<SourceImportPersistResult> importRuleText(
    String text, {
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
  }) async {
    final decoded = await _decodeJsonText(text);
    return _importDecodedJson(decoded, existingStrategy: existingStrategy);
  }

  /// Imports from either a subscription URL or pasted JSON content.
  Future<SourceImportPersistResult> importRuleUrl(
    String input, {
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
  }) async {
    final text = input.trim();
    if (text.isEmpty) {
      throw const SourceImportException('请输入书源链接或 JSON 内容');
    }
    if (text.startsWith('{') || text.startsWith('[')) {
      return importRuleText(text, existingStrategy: existingStrategy);
    }

    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const SourceImportException('链接格式不正确，请输入 http(s) 地址');
    }

    final decoded = await _fetchSubscription(text);
    return _importDecodedJson(decoded, existingStrategy: existingStrategy);
  }

  Future<SourceImportPersistResult> _importDecodedJson(
    Object? decoded, {
    required ExistingSourceStrategy existingStrategy,
  }) async {
    final resolved = decoded is Map && decoded['sourceUrls'] is List
        ? await _resolveSourceUrls(decoded)
        : decoded;

    SourceImporter? importer;
    for (final candidate in importers) {
      if (candidate.canHandleJson(resolved)) {
        importer = candidate;
        break;
      }
    }
    if (importer == null) {
      throw const SourceImportException('暂不支持此规则文件格式');
    }

    final SourceImportParseResult parseResult;
    try {
      parseResult = await importer.parseJson(resolved);
    } on SourceImportException {
      rethrow;
    } catch (_) {
      throw const SourceImportException('书源规则解析失败');
    }
    if (parseResult.candidates.isEmpty) {
      throw const SourceImportException('未找到可导入的书源');
    }

    try {
      return await repository.upsertImportedSources(
        parseResult,
        existingStrategy: existingStrategy,
      );
    } on SourceImportException {
      rethrow;
    } catch (_) {
      throw const SourceImportException('书源保存失败，请稍后重试');
    }
  }

  Future<Object?> _fetchSubscription(String url, {int depth = 0}) async {
    if (depth > _maxSubscriptionDepth) {
      throw const SourceImportException('订阅层级过深，已停止导入');
    }

    final withoutUserAgent = url.endsWith(_requestWithoutUaSuffix);
    final target = withoutUserAgent
        ? url.substring(0, url.length - _requestWithoutUaSuffix.length)
        : url;
    if (target.trim().isEmpty) {
      throw const SourceImportException('订阅地址为空');
    }

    final String text;
    try {
      text = await _fetch(target, withoutUserAgent: withoutUserAgent);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw SourceImportException(
        status == null ? '网络请求失败，请检查链接是否可访问' : '网络请求失败（HTTP $status）',
      );
    } on FormatException {
      throw const SourceImportException('订阅内容编码不受支持，请使用 UTF-8 或 GBK 编码');
    } catch (_) {
      throw const SourceImportException('网络请求失败，请检查链接是否可访问');
    }

    final decoded = await _decodeJsonText(text);
    if (decoded is Map && decoded['sourceUrls'] is List) {
      return _resolveSourceUrls(
        decoded,
        baseUri: Uri.tryParse(target),
        depth: depth,
      );
    }

    return decoded;
  }

  Future<List<Object?>> _resolveSourceUrls(
    Map decoded, {
    Uri? baseUri,
    int depth = 0,
  }) async {
    final urls = (decoded['sourceUrls'] as List)
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (urls.isEmpty) {
      throw const SourceImportException('订阅地址列表为空');
    }

    final merged = <Object?>[];
    for (final child in urls) {
      final resolved =
          baseUri == null ? child : baseUri.resolve(child).toString();
      final childDecoded = await _fetchSubscription(resolved, depth: depth + 1);
      if (childDecoded is List) {
        merged.addAll(childDecoded);
      } else if (childDecoded is Map) {
        merged.add(childDecoded);
      }
    }
    return merged;
  }

  Future<Object?> _decodeJsonText(String text) async {
    try {
      return await compute(_decodeSourceJson, text);
    } catch (_) {
      throw const SourceImportException('内容不是有效的 JSON');
    }
  }

  Future<String> _readRuleFile(File file) async {
    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const SourceImportException('无法读取规则文件');
    }
    try {
      return await textDecoder(bytes);
    } on FormatException catch (error) {
      if (error.message == 'unsupported-encoding') {
        throw const SourceImportException('文件编码不受支持，请使用 UTF-8 或 GBK 编码');
      }
      throw const SourceImportException('无法读取规则文件');
    } catch (_) {
      throw const SourceImportException('无法读取规则文件');
    }
  }
}

Object? _decodeSourceJson(String text) {
  final normalized = text.startsWith('\uFEFF') ? text.substring(1) : text;
  return jsonDecode(normalized);
}
