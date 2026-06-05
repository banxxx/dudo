import '../domain/reader_annotation.dart';

abstract interface class ReaderAnnotationRepository {
  Future<List<ReaderAnnotation>> loadAnnotations(String bookId);

  Future<void> saveAnnotation(ReaderAnnotation annotation);

  Future<void> deleteAnnotation(String annotationId);
}
