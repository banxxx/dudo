import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/source_import_models.dart';
import 'importers/source_importer.dart';
import 'source_repository.dart';

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
  });

  final SourceRepository repository;
  final List<SourceImporter> importers;

  Future<String?> pickRuleFilePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
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
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) async {
    final path = await pickRuleFilePath();
    if (path == null) return null;

    return importRuleFilePath(path, existingStrategy: existingStrategy);
  }

  Future<SourceImportPersistResult> importRuleFilePath(
    String path, {
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
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
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) async {
    final Object? decoded;
    try {
      decoded = await compute(_decodeSourceJson, text);
    } on FormatException {
      throw const SourceImportException('规则文件不是有效的 JSON');
    } catch (_) {
      throw const SourceImportException('规则文件解析失败');
    }

    SourceImporter? importer;
    for (final candidate in importers) {
      if (candidate.canHandleJson(decoded)) {
        importer = candidate;
        break;
      }
    }
    if (importer == null) {
      throw const SourceImportException('暂不支持此规则文件格式');
    }

    final SourceImportParseResult parseResult;
    try {
      parseResult = await importer.parseJson(decoded);
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
}

Future<String> _readRuleFile(File file) async {
  try {
    return await file.readAsString();
  } catch (_) {
    throw const SourceImportException('无法读取规则文件');
  }
}

Object? _decodeSourceJson(String text) => jsonDecode(text);
