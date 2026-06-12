import '../../domain/source_import_format.dart';
import '../../domain/source_import_models.dart';

abstract class SourceImporter {
  const SourceImporter();

  SourceImportFormat get format;

  bool canHandleJson(Object? json);

  Future<SourceImportParseResult> parseJson(Object? json);
}
